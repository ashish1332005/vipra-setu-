class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String status;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Vipra Member').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? 'service_taker').toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

class CategoryItem {
  const CategoryItem({
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.iconUrl = '',
    this.serviceTypes = const [],
  });

  final String name;
  final String description;
  final String imageUrl;
  final String iconUrl;
  final List<String> serviceTypes;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      name: (json['name'] ?? 'Other Services').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      iconUrl: (json['iconUrl'] ?? '').toString(),
      serviceTypes: (json['serviceTypes'] as List? ?? [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }
}

class ProviderProfile {
  const ProviderProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.category,
    required this.city,
    required this.rate,
    required this.availability,
    required this.rating,
    required this.reviewCount,
    required this.isApproved,
    this.businessName = '',
    this.address = '',
  });

  final String id;
  final String userId;
  final String name;
  final String phone;
  final String businessName;
  final String category;
  final String city;
  final String address;
  final String rate;
  final String availability;
  final double rating;
  final int reviewCount;
  final bool isApproved;

  factory ProviderProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : {};
    return ProviderProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (user['_id'] ?? user['id'] ?? json['user'] ?? '').toString(),
      name: (user['name'] ?? json['name'] ?? 'Service Provider').toString(),
      phone: (user['phone'] ?? json['phone'] ?? '').toString(),
      businessName: (json['businessName'] ?? '').toString(),
      category: (json['category'] ?? 'Other Services').toString(),
      city: (json['city'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      rate: (json['rate'] ?? 'Discuss on call').toString(),
      availability: (json['availability'] ?? 'Available').toString(),
      rating: double.tryParse((json['rating'] ?? 0).toString()) ?? 0,
      reviewCount: int.tryParse((json['reviewCount'] ?? 0).toString()) ?? 0,
      isApproved: json['isApproved'] == true,
    );
  }
}

class ServiceRequestItem {
  const ServiceRequestItem({
    required this.id,
    required this.title,
    required this.category,
    required this.city,
    required this.status,
    this.description = '',
    this.budgetLabel = '',
    this.imageUrl = '',
    this.address = '',
    this.preferredDate = '',
    this.preferredTimeSlot = '',
    this.serviceTakerName = '',
    this.serviceTakerPhone = '',
  });

  final String id;
  final String title;
  final String category;
  final String city;
  final String status;
  final String description;
  final String budgetLabel;
  final String imageUrl;
  final String address;
  final String preferredDate;
  final String preferredTimeSlot;
  final String serviceTakerName;
  final String serviceTakerPhone;

  factory ServiceRequestItem.fromJson(Map<String, dynamic> json) {
    final taker = json['serviceTaker'] is Map<String, dynamic>
        ? json['serviceTaker'] as Map<String, dynamic>
        : <String, dynamic>{};
    final takerDetails = json['takerDetails'] is Map<String, dynamic>
        ? json['takerDetails'] as Map<String, dynamic>
        : <String, dynamic>{};
    return ServiceRequestItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? takerDetails['title'] ?? 'Service Request')
          .toString(),
      category: (json['category'] ?? takerDetails['category'] ?? '').toString(),
      city: (json['city'] ?? takerDetails['city'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
      description:
          (json['description'] ?? takerDetails['description'] ?? '').toString(),
      budgetLabel:
          (json['budgetLabel'] ?? takerDetails['budgetLabel'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? takerDetails['imageUrl'] ?? '').toString(),
      address: (json['address'] ?? takerDetails['address'] ?? '').toString(),
      preferredDate:
          (json['preferredDate'] ?? takerDetails['preferredDate'] ?? '')
              .toString(),
      preferredTimeSlot:
          (json['preferredTimeSlot'] ?? takerDetails['preferredTimeSlot'] ?? '')
              .toString(),
      serviceTakerName:
          (taker['name'] ?? json['serviceTakerName'] ?? '').toString(),
      serviceTakerPhone:
          (taker['phone'] ?? json['serviceTakerPhone'] ?? '').toString(),
    );
  }
}

class AdItem {
  const AdItem(
      {required this.id,
      required this.title,
      required this.subtitle,
      required this.status,
      this.imageUrl = '',
      this.placement = 'home',
      this.placements = const [],
      this.audienceRole = 'all',
      this.targetCategory = 'all'});

  final String id;
  final String title;
  final String subtitle;
  final String status;
  final String imageUrl;
  final String placement;
  final List<String> placements;
  final String audienceRole;
  final String targetCategory;

  factory AdItem.fromJson(Map<String, dynamic> json) {
    final placements =
        json['placements'] is List ? json['placements'] as List : const [];
    return AdItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Community Update').toString(),
      subtitle: (json['subtitle'] ?? json['ctaLabel'] ?? '').toString(),
      status: (json['status'] ?? 'Active').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      placement: (json['placement'] ??
              (placements.isNotEmpty ? placements.first : 'home'))
          .toString(),
      placements: placements.map((item) => item.toString()).toList(),

      targetCategory: (json['targetCategory'] ?? 'all').toString(),
    );
  }
}

class ContactLogItem {
  const ContactLogItem({
    required this.id,
    required this.serviceTakerName,
    required this.providerName,
    required this.category,
    required this.method,
    required this.city,
    required this.rateLabel,
    required this.createdAt,
  });

  final String id;
  final String serviceTakerName;
  final String providerName;
  final String category;
  final String method;
  final String city;
  final String rateLabel;
  final String createdAt;

  factory ContactLogItem.fromJson(Map<String, dynamic> json) {
    final taker = json['serviceTaker'] is Map<String, dynamic>
        ? json['serviceTaker'] as Map<String, dynamic>
        : <String, dynamic>{};
    final provider = json['provider'] is Map<String, dynamic>
        ? json['provider'] as Map<String, dynamic>
        : <String, dynamic>{};
    return ContactLogItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      serviceTakerName: (taker['name'] ?? 'Service taker').toString(),
      providerName: (provider['name'] ?? 'Service provider').toString(),
      category: (json['category'] ?? '').toString(),
      method: (json['method'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      rateLabel: (json['rateLabel'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}
