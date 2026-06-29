import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../shared/app_widgets.dart';
import '../../shared/image_upload.dart';
import '../providers/provider_screens.dart';

class ServiceDetailsPage extends StatelessWidget {
  const ServiceDetailsPage(
      {super.key, required this.api, required this.category});

  final ApiClient api;
  final CategoryItem category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ImagePromoBanner(
              asset: serviceAssetFor(category.name),
              title: category.name,
              subtitle: category.description.isEmpty
                  ? 'Verified local providers with cash after service.'
                  : category.description,
            ),
            const SizedBox(height: 14),
            const SectionTitle('What you get'),
            const _FeatureRow(
                icon: Icons.verified_user_outlined,
                title: 'Verified providers',
                subtitle: 'Admin controlled provider accounts'),
            const _FeatureRow(
                icon: Icons.currency_rupee,
                title: 'Cash after service',
                subtitle: 'No online payment required'),
            const _FeatureRow(
                icon: Icons.timeline_outlined,
                title: 'Track request status',
                subtitle: 'Follow every step after booking'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      BookServicePage(api: api, category: category.name))),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Book Service'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProviderSearch(
                      api: api, initialCategory: category.name))),
              icon: const Icon(Icons.people_alt_outlined),
              label: const Text('See Providers'),
            ),
          ],
        ),
      ),
    );
  }
}

class BookServicePage extends StatefulWidget {
  const BookServicePage({
    super.key,
    required this.api,
    this.category = '',
    this.initialProviderUserId = '',
  });

  final ApiClient api;
  final String category;
  final String initialProviderUserId;

  @override
  State<BookServicePage> createState() => _BookServicePageState();
}

class _BookServicePageState extends State<BookServicePage> {
  late final TextEditingController _category;
  final _title = TextEditingController();
  final _issue = TextEditingController();
  final _address = TextEditingController(text: 'Bhilwara');
  final _instructions = TextEditingController();
  final _budget = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  PickedImageUpload? _image;
  late Future<List<CategoryItem>> _categories;
  late Future<List<ProviderProfile>> _providers;
  late String _selectedProvider;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _category = TextEditingController(text: widget.category);
    _selectedProvider = widget.initialProviderUserId;
    _title.text = widget.category.isEmpty
        ? 'Service request'
        : '${widget.category} service';
    _categories = _loadCategories();
    _providers = _loadProviders();
  }

  Future<List<CategoryItem>> _loadCategories() async {
    try {
      final data = await widget.api.get('/categories');
      final categories = (data['categories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CategoryItem.fromJson)
          .where((category) => category.name.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (_category.text.trim().isNotEmpty &&
          !categories.any((item) => item.name == _category.text.trim())) {
        categories.insert(0, CategoryItem(name: _category.text.trim()));
      }
      return categories;
    } catch (_) {
      return [];
    }
  }

  CategoryItem? _selectedCategory(List<CategoryItem> categories) {
    for (final category in categories) {
      if (category.name == _category.text) return category;
    }
    return null;
  }

  Future<List<ProviderProfile>> _loadProviders() async {
    final category = _title.text.trim().isNotEmpty
        ? _title.text.trim()
        : _category.text.trim();
    if (category.isEmpty) return [];
    final data = await widget.api.get('/providers', query: {
      'category': category,
      'approved': 'true',
    });
    var providers = (data['providers'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProviderProfile.fromJson)
        .where((provider) => provider.userId.isNotEmpty)
        .toList();
    if (providers.isEmpty) {
      final fallback = await widget.api.get('/providers', query: {
        'approved': 'true',
      });
      providers = (fallback['providers'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProviderProfile.fromJson)
          .where((provider) =>
              provider.userId.isNotEmpty &&
              _bookingProviderMatchesCategory(provider, category))
          .toList();
    }
    return providers;
  }

  void _refreshProviders() {
    setState(() {
      _selectedProvider = '';
      _providers = _loadProviders();
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.api.post('/service-takers/me/requests', {
        'title': _title.text.trim(),
        'category': _category.text.trim(),
        'city': 'Bhilwara',
        'address': _address.text.trim(),
        'preferredDate': _date?.toIso8601String(),
        'preferredTimeSlot': _time?.format(context),
        'description': [
          _issue.text.trim(),
          if (_date != null)
            'Preferred date: ${_date!.day}/${_date!.month}/${_date!.year}',
          if (_time != null) 'Preferred time: ${_time!.format(context)}',
          if (_address.text.trim().isNotEmpty)
            'Address: ${_address.text.trim()}',
          if (_instructions.text.trim().isNotEmpty)
            'Instructions: ${_instructions.text.trim()}',
        ].join('\n'),
        if (_image != null) 'imageFile': _image!.toJson(),
        'budgetLabel': _budget.text.trim(),
        if (_selectedProvider.isNotEmpty) 'provider': _selectedProvider,
      });
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) =>
                BookingSuccessPage(category: _category.text.trim())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ImagePromoBanner(
              asset: widget.category.isEmpty
                  ? AppAssets.heroWorkers
                  : serviceAssetFor(widget.category),
              title: 'Book in minutes',
              subtitle:
                  'Add issue, address, date and time. Pay cash after service.',
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<CategoryItem>>(
              future: _categories,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                if (categories.isEmpty) {
                  return TextField(
                    controller: _category,
                    onSubmitted: (_) => _refreshProviders(),
                    decoration: const InputDecoration(
                      labelText: 'Service category',
                    ),
                  );
                }
                final selected = categories.any(
                  (item) => item.name == _category.text,
                )
                    ? _category.text
                    : null;
                return DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration:
                      const InputDecoration(labelText: 'Service category'),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                          value: category.name, child: Text(category.name)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _category.text = value ?? '';
                      _title.clear();
                      _selectedProvider = '';
                      _providers = _loadProviders();
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<CategoryItem>>(
              future: _categories,
              builder: (context, snapshot) {
                final selectedCategory = _selectedCategory(snapshot.data ?? []);
                final services = selectedCategory?.serviceTypes ?? const [];
                if (services.isEmpty) {
                  return TextField(
                    controller: _title,
                    decoration:
                        const InputDecoration(labelText: 'Service / request title'),
                  );
                }
                final selected = services.contains(_title.text)
                    ? _title.text
                    : null;
                return DropdownButtonFormField<String>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    helperText: 'Selected category ke according service choose karo.',
                  ),
                  items: [
                    for (final service in services)
                      DropdownMenuItem(value: service, child: Text(service)),
                    const DropdownMenuItem(
                      value: '__custom__',
                      child: Text('Other / new service'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value == '__custom__') {
                        _title.clear();
                      } else {
                        _title.text = value ?? '';
                      }
                      _selectedProvider = '';
                      _providers = _loadProviders();
                    });
                  },
                );
              },
            ),
            if (_title.text.isEmpty) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'New service title'),
              ),
            ],
            const SizedBox(height: 10),
            FutureBuilder<List<ProviderProfile>>(
              future: _providers,
              builder: (context, snapshot) {
                final providers = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _selectedProvider,
                  decoration: InputDecoration(
                    labelText: 'Choose provider',
                    helperText: snapshot.connectionState ==
                            ConnectionState.waiting
                        ? 'Loading verified providers...'
                        : providers.isEmpty
                            ? 'No provider found for this category. Request will stay open.'
                            : 'Select a provider or leave empty for admin assignment.',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Any verified provider'),
                    ),
                    for (final provider in providers)
                      DropdownMenuItem(
                        value: provider.userId,
                        child: Text(
                          '${provider.name} • ${provider.rating.toStringAsFixed(1)} ★',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedProvider = value ?? ''),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _issue,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Issue description')),
            const SizedBox(height: 10),
            TextField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.date_range),
                        label: Text(_date == null
                            ? 'Date'
                            : '${_date!.day}/${_date!.month}/${_date!.year}'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule),
                        label: Text(
                            _time == null ? 'Time' : _time!.format(context)))),
              ],
            ),
            const SizedBox(height: 10),
            ImageUploadField(
              label: 'Issue image',
              image: _image,
              helperText: 'Optional photo for provider/admin reference.',
              onChanged: (image) => setState(() => _image = image),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _budget,
                decoration:
                    const InputDecoration(labelText: 'Estimated budget')),
            const SizedBox(height: 10),
            TextField(
                controller: _instructions,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Special instructions')),
            const SizedBox(height: 14),
            FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Booking...' : 'Confirm Booking')),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 60)),
        initialDate: DateTime.now());
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime() async {
    final value =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (value != null) setState(() => _time = value);
  }
}

bool _bookingProviderMatchesCategory(
    ProviderProfile provider, String category) {
  final terms = _bookingCategoryTerms(category);
  if (terms.isEmpty) return true;
  final haystack = [
    provider.category,
    provider.businessName,
    provider.name,
    provider.rate,
  ].join(' ').toLowerCase();
  return terms.any(haystack.contains);
}

Set<String> _bookingCategoryTerms(String category) {
  final normalized = category.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'all') return {};
  final terms = <String>{normalized};
  final aliases = <String, List<String>>{
    'electrician': ['electrician', 'electrical', 'electric'],
    'electrical repair': ['electrician', 'electrical', 'electric'],
    'plumber': ['plumber', 'plumbing'],
    'ac repair': ['ac repair', 'air conditioner', 'cooling'],
    'carpenter': ['carpenter', 'carpentry', 'woodwork'],
    'painter': ['painter', 'painting'],
    'cleaning': ['cleaning', 'cleaner'],
    'pandit': ['pandit', 'pandit ji', 'pooja', 'puja'],
    'pandit ji': ['pandit', 'pandit ji', 'pooja', 'puja'],
    'event management': ['event', 'events', 'event management'],
    'event': ['event', 'events', 'event management'],
  };
  aliases.forEach((key, values) {
    if (normalized.contains(key) || key.contains(normalized)) {
      terms.addAll(values);
    }
  });
  terms.addAll(normalized
      .split(RegExp(r'[\s/&,-]+'))
      .where((part) => part.trim().length > 2));
  return terms;
}

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 36),
              const Icon(Icons.check_circle, color: AppTheme.emerald, size: 92),
              const SizedBox(height: 18),
              const Text('Booking Created',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                  'Your $category request has been submitted. Admin/provider will respond soon.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 22),
              const PremiumCard(
                  child: ListTile(
                      leading: Icon(Icons.currency_rupee),
                      title: Text('Payment Mode'),
                      subtitle: Text('Cash After Service'))),
              const SizedBox(height: 14),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to app')),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingDetailsPage extends StatelessWidget {
  const BookingDetailsPage({super.key, required this.api, required this.item});

  final ApiClient api;
  final ServiceRequestItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ImagePromoBanner(
              asset: serviceAssetFor(item.category),
              title: item.title,
              subtitle: '${item.category} | ${item.city} | ${item.status}',
            ),
            const SizedBox(height: 14),
            PremiumCard(
                child: Text(
                    item.description.isEmpty
                        ? 'No description added.'
                        : item.description,
                    style: const TextStyle(height: 1.45))),
            if (item.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 180,
                  child: AppRemoteImage(
                    url: item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const LiveStatusTimeline(),
            const SizedBox(height: 14),
            if (item.status == 'completed')
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _ReviewSheet(api: api, item: item),
                  ),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Rate this service'),
                ),
              ),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.call),
                        label: const Text('Call'))),
                const SizedBox(width: 8),
                Expanded(
                    child: FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Chat'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.api, required this.item});

  final ApiClient api;
  final ServiceRequestItem item;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _comment = TextEditingController();
  double _rating = 5;
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.api.post('/service-takers/me/reviews', {
        'request': widget.item.id,
        'rating': _rating.round(),
        'comment': _comment.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const SectionTitle('Rate Service'),
            Text(widget.item.title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.round().toString(),
              onChanged: (value) => setState(() => _rating = value),
            ),
            TextField(
              controller: _comment,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Review comment'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(_message!,
                  style: const TextStyle(
                      color: AppTheme.crimson, fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.star),
              label: Text(_busy ? 'Submitting...' : 'Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveStatusTimeline extends StatelessWidget {
  const LiveStatusTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Booking Accepted',
      'Provider Assigned',
      'On The Way',
      'Work Started',
      'Work Completed'
    ];
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Live Status'),
          for (var i = 0; i < steps.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                  backgroundColor: i < 2 ? AppTheme.emerald : AppTheme.line,
                  child: Icon(i < 2 ? Icons.check : Icons.more_horiz,
                      color: Colors.white)),
              title: Text(steps[i],
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(i < 2 ? 'Completed' : 'Pending'),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(
      {required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppTheme.saffron),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
