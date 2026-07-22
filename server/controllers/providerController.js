const ProviderProfile = require('../models/ProviderProfile');
const User = require('../models/User');
const Service = require('../models/Service');
const ServiceRequest = require('../models/ServiceRequest');
const Review = require('../models/Review');
const ContactLog = require('../models/ContactLog');
const asyncHandler = require('../utils/asyncHandler');
const createNotification = require('../utils/createNotification');
const saveImageUpload = require('../utils/saveImageUpload');

const escapeRegex = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const categoryAliases = {
  electrician: ['electrician', 'electrical', 'electrical repair', 'electric'],
  'electrical repair': ['electrician', 'electrical', 'electrical repair', 'electric'],
  plumber: ['plumber', 'plumbing', 'plumbing service'],
  'ac repair': ['ac repair', 'air conditioner', 'air conditioning', 'cooling'],
  carpenter: ['carpenter', 'carpentry', 'woodwork'],
  painter: ['painter', 'painting', 'painting service'],
  cleaning: ['cleaning', 'cleaner', 'house cleaning'],
  pandit: ['pandit', 'pandit ji', 'pooja', 'puja'],
  'pandit ji': ['pandit', 'pandit ji', 'pooja', 'puja'],
  event: ['event', 'events', 'event management', 'event manager'],
  events: ['event', 'events', 'event management', 'event manager'],
  'event management': ['event', 'events', 'event management', 'event manager'],
};

const buildCategoryRegexes = (category) => {
  const normalized = String(category || '').trim().toLowerCase();
  if (!normalized || normalized === 'all') return [];

  const terms = new Set([normalized]);
  Object.entries(categoryAliases).forEach(([key, values]) => {
    if (normalized.includes(key) || key.includes(normalized)) {
      values.forEach((value) => terms.add(value));
    }
  });

  normalized
    .split(/[\s/&,-]+/)
    .map((part) => part.trim())
    .filter((part) => part.length > 2)
    .forEach((part) => terms.add(part));

  return [...terms].map((term) => new RegExp(escapeRegex(term), 'i'));
};

const getProviderUserId = (provider) => {
  const user = provider?.user;
  return (user?._id || user || '').toString();
};

const getCurrentProviderIds = async (userId) => {
  const profile = await ProviderProfile.findOne({ user: userId }).select('_id');
  return [userId, profile?._id].filter(Boolean);
};

const listProviders = asyncHandler(async (req, res) => {
  const { category, city, approved = 'true', nearLat, nearLng } = req.query;
  const filter = {};

  const categoryRegexes = buildCategoryRegexes(category);
  if (categoryRegexes.length) {
    filter.$or = [
      { category: { $in: categoryRegexes } },
      { skills: { $in: categoryRegexes } },
      { businessName: { $in: categoryRegexes } },
    ];
  }
  if (city) filter.city = city;
  if (approved !== 'all') filter.isApproved = approved === 'true';

  let providers = await ProviderProfile.find(filter).populate('user', 'name email phone status');

  if (categoryRegexes.length) {
    const serviceMatches = await Service.find({
      isActive: true,
      moderationStatus: { $ne: 'rejected' },
      $or: [
        { category: { $in: categoryRegexes } },
        { title: { $in: categoryRegexes } },
        { description: { $in: categoryRegexes } },
      ],
    }).distinct('provider');

    const seenProviderIds = new Set(providers.map(getProviderUserId));
    const missingProviderIds = serviceMatches
      .map((provider) => provider?.toString())
      .filter((providerId) => providerId && !seenProviderIds.has(providerId));

    if (missingProviderIds.length) {
      const serviceProviderFilter = {
        user: { $in: missingProviderIds },
      };
      if (city) serviceProviderFilter.city = city;
      if (approved !== 'all') serviceProviderFilter.isApproved = approved === 'true';

      const serviceProviders = await ProviderProfile.find(serviceProviderFilter)
        .populate('user', 'name email phone status');
      providers = [...providers, ...serviceProviders];
    }
  }

  if (approved !== 'all') {
    providers = providers.filter((provider) =>
      approved === 'true'
        ? provider.user?.status !== 'blocked'
        : true
    );
  }

  const latitude = Number(nearLat);
  const longitude = Number(nearLng);
  if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
    providers = providers
      .map((provider) => {
        const data = provider.toObject();
        const location = data.currentLocation || {};
        data.distanceKm = Number.isFinite(location.lat) && Number.isFinite(location.lng)
          ? calculateDistanceKm(latitude, longitude, location.lat, location.lng)
          : null;
        return data;
      })
      .sort((a, b) => (a.distanceKm ?? Number.MAX_VALUE) - (b.distanceKm ?? Number.MAX_VALUE));
  }

  res.json({ providers });
});

const getMyProviderProfile = asyncHandler(async (req, res) => {
  const profile = await ProviderProfile.findOne({ user: req.user._id }).populate('user', 'name email phone status');
  res.json({ profile });
});

const updateMyProviderProfile = asyncHandler(async (req, res) => {
  const allowedFields = [
    'businessName',
    'category',
    'skills',
    'city',
    'address',
    'experienceYears',
    'rate',
    'availability',
    'profileImageUrl',
    'coverImageUrl',
    'weeklyAvailability',
    'blackoutDates',
    'businessSettings',
    'responseTimeLabel',
    'portfolio',
  ];

  const updates = allowedFields.reduce((data, field) => {
    if (req.body[field] !== undefined) data[field] = req.body[field];
    return data;
  }, {});

  if (req.body.profileImageFile?.dataUrl) {
    updates.profileImageUrl = saveProviderImage(req.body.profileImageFile);
  }

  if (req.body.coverImageFile?.dataUrl) {
    updates.coverImageUrl = saveProviderImage(req.body.coverImageFile);
  }

  if (req.body.name !== undefined) {
    await User.findByIdAndUpdate(
      req.user._id,
      { name: String(req.body.name).trim() || req.user.name },
      { runValidators: true }
    );
  }

  const profile = await ProviderProfile.findOneAndUpdate(
    { user: req.user._id },
    {
      ...updates,
      $setOnInsert: { user: req.user._id },
    },
    { new: true, runValidators: true, upsert: true, setDefaultsOnInsert: true }
  );

  const populatedProfile = await profile.populate('user', 'name email phone status');
  res.json({ profile: populatedProfile });
});

const submitMyKyc = asyncHandler(async (req, res) => {
  const { documentType, documentNumber, documentUrl, documentFile } = req.body;

  if (!documentType || !documentNumber) {
    res.status(400);
    throw new Error('Document type and number are required');
  }

  if (!documentFile?.dataUrl) {
    res.status(400);
    throw new Error('A KYC document upload is required');
  }
  const uploadedDocumentUrl = saveKycDocument(documentFile);

  const profile = await ProviderProfile.findOneAndUpdate(
    { user: req.user._id },
    {
      kyc: {
        status: 'submitted',
        documentType,
        documentNumber,
        documentUrl: uploadedDocumentUrl,
        submittedAt: new Date(),
      },
    },
    { new: true, runValidators: true }
  );

  res.json({ profile });
});

const saveKycDocument = (documentFile) => saveImageUpload(documentFile, {
  folder: 'kyc',
  label: 'KYC document',
  maxSizeMb: 5,
  allowedTypes: {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp',
    'application/pdf': '.pdf',
  },
});

const saveProviderImage = (imageFile) => {
  return saveImageUpload(imageFile, {
    folder: 'providers',
    label: 'Provider image',
    maxSizeMb: 5,
  });
};

const calculateDistanceKm = (lat1, lng1, lat2, lng2) => {
  const toRad = (value) => (value * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2
    + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Number((earthRadiusKm * c).toFixed(1));
};

const createService = asyncHandler(async (req, res) => {
  const { title, category, description, priceLabel, durationLabel, packageType, includes, isActive } = req.body;
  const profile = await ProviderProfile.findOne({ user: req.user._id }).select('isApproved');

  if (!profile?.isApproved || req.user.status !== 'active') {
    res.status(403);
    throw new Error('Provider approval is required before publishing services');
  }

  if (!title || !category || !description) {
    res.status(400);
    throw new Error('Title, category, and description are required');
  }

  const service = await Service.create({
    provider: req.user._id,
    title,
    category,
    description,
    priceLabel,
    durationLabel,
    packageType,
    includes,
    isActive: isActive !== false,
    moderationStatus: 'pending',
    isFeatured: false,
  });

  res.status(201).json({ service });
});

const listMyServices = asyncHandler(async (req, res) => {
  const services = await Service.find({ provider: req.user._id }).sort('-createdAt');
  res.json({ services });
});

const updateMyService = asyncHandler(async (req, res) => {
  const updates = {};
  [
    'title',
    'category',
    'description',
    'priceLabel',
    'durationLabel',
    'packageType',
    'includes',
    'isActive',
  ].forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  const service = await Service.findOneAndUpdate(
    { _id: req.params.id, provider: req.user._id },
    updates,
    { new: true, runValidators: true }
  );

  if (!service) {
    res.status(404);
    throw new Error('Service not found');
  }

  res.json({ service });
});

const deleteMyService = asyncHandler(async (req, res) => {
  const service = await Service.findOneAndDelete({
    _id: req.params.id,
    provider: req.user._id,
  });

  if (!service) {
    res.status(404);
    throw new Error('Service not found');
  }

  res.json({ message: 'Service deleted' });
});

const listAssignedRequests = asyncHandler(async (req, res) => {
  const providerIds = await getCurrentProviderIds(req.user._id);
  const requests = await ServiceRequest.find({ provider: { $in: providerIds } }).populate('serviceTaker', 'name email phone');

  const enriched = requests.map((r) => {
    const obj = r.toObject();
    obj.takerDetails = Object.assign({}, obj.serviceTaker || {}, {
      address: obj.address || '',
      city: obj.city || '',
      preferredDate: obj.preferredDate || null,
      preferredTimeSlot: obj.preferredTimeSlot || '',
      budgetLabel: obj.budgetLabel || '',
      title: obj.title || '',
      description: obj.description || '',
      imageUrl: obj.imageUrl || '',
      issueImages: obj.issueImages || [],
    });
    return obj;
  });

  res.json({ requests: enriched });
});

const listOpenRequests = asyncHandler(async (req, res) => {
  const profile = await ProviderProfile.findOne({ user: req.user._id });
  const filter = { status: 'open' };

  const categoryRegexes = buildCategoryRegexes(profile?.category);
  if (categoryRegexes.length) filter.category = { $in: categoryRegexes };
  if (profile?.city) filter.city = profile.city;

  const requests = await ServiceRequest.find(filter)
    .populate('serviceTaker', 'name email phone')
    .sort('-createdAt');

  const enriched = requests.map((r) => {
    const obj = r.toObject();
    obj.takerDetails = Object.assign({}, obj.serviceTaker || {}, {
      address: obj.address || '',
      city: obj.city || '',
      preferredDate: obj.preferredDate || null,
      preferredTimeSlot: obj.preferredTimeSlot || '',
      budgetLabel: obj.budgetLabel || '',
      title: obj.title || '',
      description: obj.description || '',
      imageUrl: obj.imageUrl || '',
      issueImages: obj.issueImages || [],
    });
    return obj;
  });

  res.json({ requests: enriched });
});

const claimRequest = asyncHandler(async (req, res) => {
  const profile = await ProviderProfile.findOne({ user: req.user._id });
  if (!profile?.isApproved || req.user.status !== 'active') {
    res.status(403);
    throw new Error('Provider approval is required before claiming requests');
  }

  const request = await ServiceRequest.findOneAndUpdate(
    { _id: req.params.id, status: 'open' },
    {
      provider: req.user._id,
      status: 'assigned',
      $push: {
        statusHistory: {
          status: 'assigned',
          changedBy: req.user._id,
          note: 'Provider claimed this lead',
        },
      },
    },
    { new: true, runValidators: true }
  ).populate('serviceTaker', 'name email phone');

  if (!request) {
    res.status(404);
    throw new Error('Open request not found');
  }

  await createNotification({
    user: request.serviceTaker?._id || request.serviceTaker,
    title: 'Provider assigned',
    message: `${req.user.name} claimed your service request.`,
    type: 'request',
    link: '/taker/requests',
  });

  const obj = request ? request.toObject() : null;
  if (obj) {
    obj.takerDetails = Object.assign({}, obj.serviceTaker || {}, {
      address: obj.address || '',
      city: obj.city || '',
      preferredDate: obj.preferredDate || null,
      preferredTimeSlot: obj.preferredTimeSlot || '',
      budgetLabel: obj.budgetLabel || '',
      title: obj.title || '',
      description: obj.description || '',
      imageUrl: obj.imageUrl || '',
      issueImages: obj.issueImages || [],
    });
  }

  res.json({ request: obj });
});

const updateAssignedRequestStatus = asyncHandler(async (req, res) => {
  const { status, note = '' } = req.body;
  const providerIds = await getCurrentProviderIds(req.user._id);

  if (!['assigned', 'in_progress', 'completed', 'cancelled'].includes(status)) {
    res.status(400);
    throw new Error('Invalid request status');
  }

  const request = await ServiceRequest.findOneAndUpdate(
    { _id: req.params.id, provider: { $in: providerIds } },
    {
      status,
      $push: {
        statusHistory: {
          status,
          changedBy: req.user._id,
          note: note || `Provider moved request to ${status}`,
        },
      },
    },
    { new: true, runValidators: true }
  ).populate('serviceTaker', 'name email phone');

  if (!request) {
    res.status(404);
    throw new Error('Assigned request not found');
  }

  if (status === 'completed') {
    await ProviderProfile.findOneAndUpdate(
      { user: req.user._id },
      { $inc: { completedJobs: 1 } }
    );
  }

  await createNotification({
    user: request.serviceTaker?._id || request.serviceTaker,
    title: 'Request updated',
    message: note
      ? `Your request is now ${status}: ${note}`
      : `Your request is now ${status}.`,
    type: 'request',
    link: '/taker/requests',
  });

  const obj = request ? request.toObject() : null;
  if (obj) {
    obj.takerDetails = Object.assign({}, obj.serviceTaker || {}, {
      address: obj.address || '',
      city: obj.city || '',
      preferredDate: obj.preferredDate || null,
      preferredTimeSlot: obj.preferredTimeSlot || '',
      budgetLabel: obj.budgetLabel || '',
      title: obj.title || '',
      description: obj.description || '',
      imageUrl: obj.imageUrl || '',
      issueImages: obj.issueImages || [],
    });
  }

  res.json({ request: obj });
});

const updateLeadPipeline = asyncHandler(async (req, res) => {
  const { pipelineStage, priority, nextFollowUpAt, note } = req.body;
  const providerIds = await getCurrentProviderIds(req.user._id);
  const updates = {};

  if (pipelineStage) {
    if (!['new', 'contacted', 'quoted', 'scheduled', 'won', 'lost'].includes(pipelineStage)) {
      res.status(400);
      throw new Error('Invalid pipeline stage');
    }
    updates.pipelineStage = pipelineStage;
  }

  if (priority) {
    if (!['low', 'normal', 'high', 'urgent'].includes(priority)) {
      res.status(400);
      throw new Error('Invalid priority');
    }
    updates.priority = priority;
  }

  if (nextFollowUpAt !== undefined) updates.nextFollowUpAt = nextFollowUpAt || null;
  if (note) {
    updates.$push = {
      internalNotes: {
        note,
        createdBy: req.user._id,
      },
    };
  }

  const request = await ServiceRequest.findOneAndUpdate(
    { _id: req.params.id, provider: { $in: providerIds } },
    updates,
    { new: true, runValidators: true }
  ).populate('serviceTaker', 'name email phone');

  if (!request) {
    res.status(404);
    throw new Error('Lead not found');
  }

  const obj = request ? request.toObject() : null;
  if (obj) {
    obj.takerDetails = Object.assign({}, obj.serviceTaker || {}, {
      address: obj.address || '',
      city: obj.city || '',
      preferredDate: obj.preferredDate || null,
      preferredTimeSlot: obj.preferredTimeSlot || '',
      budgetLabel: obj.budgetLabel || '',
      title: obj.title || '',
      description: obj.description || '',
      imageUrl: obj.imageUrl || '',
      issueImages: obj.issueImages || [],
    });
  }

  res.json({ request: obj });
});

const sendQuote = asyncHandler(async (req, res) => {
  const { amount, priceLabel, scope, validUntil } = req.body;
  const providerIds = await getCurrentProviderIds(req.user._id);

  if (!amount && !priceLabel) {
    res.status(400);
    throw new Error('Quote amount or price label is required');
  }

  const request = await ServiceRequest.findOneAndUpdate(
    { _id: req.params.id, provider: { $in: providerIds } },
    {
      pipelineStage: 'quoted',
      quote: {
        amount,
        priceLabel,
        scope,
        validUntil,
        status: 'sent',
        sentAt: new Date(),
      },
      $push: {
        statusHistory: {
          status: 'assigned',
          changedBy: req.user._id,
          note: 'Quote sent by provider',
        },
      },
    },
    { new: true, runValidators: true }
  ).populate('serviceTaker', 'name email phone');

  if (!request) {
    res.status(404);
    throw new Error('Lead not found');
  }

  await createNotification({
    user: request.serviceTaker._id,
    title: 'Quote received',
    message: `${req.user.name} sent a quote for ${request.title}.`,
    type: 'request',
    link: '/taker/requests',
  });

  const obj = request ? request.toObject() : null;
  if (obj) {
    obj.takerDetails = Object.assign({}, obj.serviceTaker || {}, {
      address: obj.address || '',
      city: obj.city || '',
      preferredDate: obj.preferredDate || null,
      preferredTimeSlot: obj.preferredTimeSlot || '',
      budgetLabel: obj.budgetLabel || '',
      title: obj.title || '',
      description: obj.description || '',
      imageUrl: obj.imageUrl || '',
      issueImages: obj.issueImages || [],
    });
  }

  res.json({ request: obj });
});

const getBusinessAnalytics = asyncHandler(async (req, res) => {
  const [profile, services, requests, reviews] = await Promise.all([
    ProviderProfile.findOne({ user: req.user._id }),
    Service.find({ provider: req.user._id }),
    ServiceRequest.find({ provider: req.user._id }),
    Review.find({ provider: req.user._id, status: 'approved' }),
  ]);

  const won = requests.filter((request) => request.pipelineStage === 'won' || request.status === 'completed').length;
  const quoted = requests.filter((request) => request.quote?.status === 'sent').length;
  const totalQuoteValue = requests.reduce((total, request) => total + (request.quote?.amount || 0), 0);
  const pendingFollowUps = requests.filter((request) =>
    request.nextFollowUpAt && new Date(request.nextFollowUpAt) <= new Date()
  ).length;

  res.json({
    analytics: {
      liveServices: services.filter((service) => service.isActive).length,
      totalLeads: requests.length,
      openLeads: requests.filter((request) => !['completed', 'cancelled'].includes(request.status)).length,
      quoted,
      won,
      conversionRate: requests.length ? Math.round((won / requests.length) * 100) : 0,
      totalQuoteValue,
      pendingFollowUps,
      rating: profile?.rating || 0,
      reviewCount: reviews.length,
    },
  });
});

const listMyReviews = asyncHandler(async (req, res) => {
  const reviews = await Review.find({ provider: req.user._id })
    .populate('serviceTaker', 'name')
    .sort('-createdAt');

  res.json({ reviews });
});

const listMyContactLogs = asyncHandler(async (req, res) => {
  const contactLogs = await ContactLog.find({ provider: req.user._id })
    .populate('serviceTaker', 'name phone')
    .populate('providerProfile', 'businessName category city rate')
    .sort('-createdAt')
    .limit(100);

  res.json({ contactLogs });
});

const updateMyLocation = asyncHandler(async (req, res) => {
  const { lat, lng, accuracy, locationSharing = true } = req.body;
  const latitude = Number(lat);
  const longitude = Number(lng);

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    res.status(400);
    throw new Error('Latitude and longitude are required');
  }

  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    res.status(400);
    throw new Error('Invalid location coordinates');
  }

  const profile = await ProviderProfile.findOneAndUpdate(
    { user: req.user._id },
    {
      locationSharing: Boolean(locationSharing),
      currentLocation: {
        lat: latitude,
        lng: longitude,
        accuracy: Number.isFinite(Number(accuracy)) ? Number(accuracy) : undefined,
        updatedAt: new Date(),
      },
    },
    { new: true, runValidators: true }
  ).populate('user', 'name email phone status');

  if (!profile) {
    res.status(404);
    throw new Error('Provider profile not found');
  }

  res.json({ profile });
});

module.exports = {
  listProviders,
  getMyProviderProfile,
  updateMyProviderProfile,
  submitMyKyc,
  createService,
  listMyServices,
  updateMyService,
  deleteMyService,
  listAssignedRequests,
  listOpenRequests,
  claimRequest,
  updateAssignedRequestStatus,
  updateLeadPipeline,
  sendQuote,
  getBusinessAnalytics,
  listMyReviews,
  listMyContactLogs,
  updateMyLocation,
};
