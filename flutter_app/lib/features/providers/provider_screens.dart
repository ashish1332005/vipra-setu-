import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../shared/app_widgets.dart';
import '../../shared/image_upload.dart';

class ProviderSearch extends StatefulWidget {
  const ProviderSearch({
    super.key,
    required this.api,
    this.initialCategory,
    this.initialQuery,
  });

  final ApiClient api;
  final String? initialCategory;
  final String? initialQuery;

  @override
  State<ProviderSearch> createState() => _ProviderSearchState();
}

class _ProviderSearchState extends State<ProviderSearch> {
  final _search = TextEditingController();
  final _city = TextEditingController();
  late Future<List<ProviderProfile>> _future;

  @override
  void initState() {
    super.initState();
    _search.text = widget.initialQuery ?? '';
    _future = _load();
  }

  Future<List<ProviderProfile>> _load() async {
    final category = widget.initialCategory?.trim();
    final data = await widget.api.get('/providers', query: {
      if (category != null && category.isNotEmpty) 'category': category,
      if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
    });
    var providers = (data['providers'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProviderProfile.fromJson)
        .toList();
    if (providers.isEmpty && category != null && category.isNotEmpty) {
      final fallback = await widget.api.get('/providers', query: {
        if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
      });
      providers = (fallback['providers'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProviderProfile.fromJson)
          .where((provider) => _matchesCategory(provider, category))
          .toList();
    }
    return providers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<ProviderProfile>>(
          future: _future,
          builder: (context, snapshot) {
            final query = _search.text.toLowerCase();
            final providers = (snapshot.data ?? [])
                .where((provider) => _matchesSearch(provider, query))
                .toList();
            return AppBackground(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  MediaQuery.paddingOf(context).bottom + 120,
                ),
                children: [
                  const CompactHero(
                    title: 'Find Providers',
                    subtitle:
                        'Search verified local professionals by seva and city.',
                    icon: Icons.people_alt_outlined,
                  ),
                  const SizedBox(height: 12),
                  _ProviderFilterCard(
                    search: _search,
                    city: _city,
                    onSearchChanged: () => setState(() {}),
                    onApply: () => setState(() => _future = _load()),
                  ),
                  const SizedBox(height: 14),
                  SectionTitle('${providers.length} providers found',
                      subtitle: 'Tap call or WhatsApp to contact directly'),
                  for (final provider in providers)
                    ProviderCard(provider: provider, api: widget.api),
                  if (providers.isEmpty)
                    const EmptyState(
                        text: 'Abhi is filter me provider nahi mila.',
                        icon: Icons.search_off_outlined),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

bool _matchesSearch(ProviderProfile provider, String query) {
  final value = query.trim().toLowerCase();
  if (value.isEmpty) return true;
  return [
    provider.name,
    provider.businessName,
    provider.category,
    provider.city,
    provider.address,
    provider.rate,
  ].any((field) => field.toLowerCase().contains(value));
}

bool _matchesCategory(ProviderProfile provider, String category) {
  final terms = _categoryTerms(category);
  if (terms.isEmpty) return true;
  final haystack = [
    provider.category,
    provider.businessName,
    provider.name,
    provider.rate,
  ].join(' ').toLowerCase();
  return terms.any(haystack.contains);
}

Set<String> _categoryTerms(String category) {
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

class _ProviderFilterCard extends StatelessWidget {
  const _ProviderFilterCard({
    required this.search,
    required this.city,
    required this.onSearchChanged,
    required this.onApply,
  });

  final TextEditingController search;
  final TextEditingController city;
  final VoidCallback onSearchChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TextField(
            controller: search,
            onChanged: (_) => onSearchChanged(),
            decoration: const InputDecoration(
              hintText: 'Search provider, seva, city',
              prefixIcon: Icon(Icons.search),
              labelText: 'Search',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: city,
                  decoration: const InputDecoration(
                    labelText: 'City filter',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 54,
                height: 54,
                child: IconButton.filled(
                  onPressed: onApply,
                  icon: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProviderCard extends StatelessWidget {
  const ProviderCard({super.key, required this.provider, this.api});

  final ProviderProfile provider;
  final ApiClient? api;

  String _phoneUriValue(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _whatsAppPhone(String value) {
    final digits = _phoneUriValue(value);
    if (digits.startsWith('91') && digits.length > 10) return digits;
    return '91$digits';
  }

  Future<void> _launch(String value, bool whatsapp) async {
    await _trackContact(whatsapp ? 'WhatsApp' : 'Call');
    final uri = whatsapp
        ? Uri.parse('https://wa.me/${_whatsAppPhone(value)}')
        : Uri.parse('tel:${_phoneUriValue(value)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _trackContact(String method) async {
    try {
      await api?.post('/service-takers/me/contact-logs', {
        'provider': provider.userId,
        'providerProfile': provider.id,
        'category': provider.category,
        'method': method.toLowerCase(),
        'city': provider.city.isEmpty ? 'Local' : provider.city,
        'rateLabel': provider.rate,
        'note':
            'Service taker contacted provider through $method from mobile app.',
      });
    } catch (_) {
      // Contact should still open if tracking fails because of role or network.
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        provider.businessName.isEmpty ? provider.name : provider.businessName;
    final photo = provider.category.toLowerCase().contains('plumb')
        ? AppAssets.providerPlumber
        : AppAssets.providerElectrician;
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProviderDetailsPage(provider: provider, api: api))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Image.asset(photo,
                            width: 76, height: 76, fit: BoxFit.cover),
                        Positioned(
                          right: 5,
                          bottom: 5,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(serviceIconFor(provider.category),
                                color: AppTheme.saffron, size: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink)),
                        const SizedBox(height: 3),
                        Text('${provider.category} | ${provider.city}',
                            style: const TextStyle(
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (provider.isApproved)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified,
                          color: AppTheme.success, size: 21),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ProviderMetric(
                      icon: Icons.currency_rupee,
                      label: provider.rate,
                      color: AppTheme.saffron),
                  const SizedBox(width: 8),
                  _ProviderMetric(
                      icon: Icons.schedule_outlined,
                      label: provider.availability,
                      color: AppTheme.navy),
                  const SizedBox(width: 8),
                  _ProviderMetric(
                      icon: Icons.star,
                      label: provider.rating.toStringAsFixed(1),
                      color: AppTheme.amber),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: provider.phone.isEmpty
                          ? null
                          : () => _launch(provider.phone, false),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: provider.phone.isEmpty
                          ? null
                          : () => _launch(provider.phone, true),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderMetric extends StatelessWidget {
  const _ProviderMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProviderDetailsPage extends StatelessWidget {
  const ProviderDetailsPage({super.key, required this.provider, this.api});

  final ProviderProfile provider;
  final ApiClient? api;

  String _phoneUriValue(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _whatsAppPhone(String value) {
    final digits = _phoneUriValue(value);
    if (digits.startsWith('91') && digits.length > 10) return digits;
    return '91$digits';
  }

  Future<void> _trackContact(String method) async {
    try {
      await api?.post('/service-takers/me/contact-logs', {
        'provider': provider.userId,
        'providerProfile': provider.id,
        'category': provider.category,
        'method': method.toLowerCase(),
        'city': provider.city.isEmpty ? 'Local' : provider.city,
        'rateLabel': provider.rate,
        'note':
            'Service taker contacted provider through $method from provider detail page.',
      });
    } catch (_) {
      // Contact should still open even when tracking fails for a non-taker role.
    }
  }

  Future<void> _launchContact(String value, bool whatsapp) async {
    await _trackContact(whatsapp ? 'WhatsApp' : 'Call');
    final uri = whatsapp
        ? Uri.parse('https://wa.me/${_whatsAppPhone(value)}')
        : Uri.parse('tel:${_phoneUriValue(value)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final photo = provider.category.toLowerCase().contains('plumb')
        ? AppAssets.providerPlumber
        : AppAssets.providerElectrician;
    return Scaffold(
      appBar: AppBar(
          title: Text(provider.businessName.isEmpty
              ? provider.name
              : provider.businessName)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PremiumCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 250,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(photo, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.navy.withValues(alpha: .82),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.businessName.isEmpty
                                  ? provider.name
                                  : provider.businessName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${provider.category} | ${provider.city} | ${provider.rating.toStringAsFixed(1)} rating',
                              style: const TextStyle(
                                  color: Color(0xFFFFEAD8),
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            StatsGrid(stats: {
              'Experience': provider.availability,
              'Reviews': provider.reviewCount,
              'Rating': provider.rating.toStringAsFixed(1),
              'Rate': provider.rate,
            }),
            const SizedBox(height: 14),
            const SectionTitle('Service area & profile'),
            PremiumCard(
                child: Text(provider.address.isEmpty
                    ? 'Service area: ${provider.city.isEmpty ? 'Local area' : provider.city}'
                    : provider.address)),
            const SizedBox(height: 14),
            const SectionTitle('Service promise'),
            const InfoStrip(
                icon: Icons.verified_user_outlined,
                text:
                    'Verified profile, fair pricing aur direct call/WhatsApp support.'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: FilledButton.icon(
                        onPressed: provider.phone.isEmpty
                            ? null
                            : () => _launchContact(provider.phone, false),
                        icon: const Icon(Icons.call),
                        label: const Text('Call'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: provider.phone.isEmpty
                            ? null
                            : () => _launchContact(provider.phone, true),
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

class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key, required this.api, required this.user});

  final ApiClient api;
  final AppUser user;

  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome> {
  late Future<Map<String, dynamic>> _future;
  late Future<List<Map<String, dynamic>>> _ads;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _ads = _loadAds();
  }

  Future<Map<String, dynamic>> _load() async {
    final profile = await widget.api.get('/providers/me');
    final analytics = await widget.api.get('/providers/me/analytics');
    return {'profile': profile['profile'], 'analytics': analytics['analytics']};
  }

  Future<List<Map<String, dynamic>>> _loadAds() async {
    try {
      final data = await widget.api.get('/ads', query: {
        'role': 'service_provider',
        'placement': 'dashboard',
      });
      return (data['ads'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final profile = snapshot.data?['profile'] as Map<String, dynamic>?;
        final analytics =
            snapshot.data?['analytics'] as Map<String, dynamic>? ?? {};
        return AppBackground(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CommunityHero(
                  name: widget.user.name,
                  title:
                      'Leads, services aur profile performance ko yahan manage karo.'),
              const SizedBox(height: 14),
              const InfoStrip(
                icon: Icons.trending_up_outlined,
                text:
                    'Keep your profile updated, respond fast and improve your local visibility.',
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _ads,
                builder: (context, snapshot) {
                  final ads = snapshot.data ?? [];
                  if (ads.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: LiveAdPreviewCard(ad: ads.first),
                  );
                },
              ),
              const SizedBox(height: 14),
              PremiumCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_outlined,
                      color: AppTheme.deepRed),
                  title: Text(
                      (profile?['businessName'] ?? widget.user.name).toString(),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                      '${profile?['category'] ?? 'Service'} | ${profile?['availability'] ?? 'Available'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ProviderProfileEditSheet(
                        api: widget.api,
                        profile: profile ?? {},
                        onSaved: () => setState(() => _future = _load()),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              StatsGrid(stats: {
                'Live services': analytics['liveServices'] ?? 0,
                'Total leads': analytics['totalLeads'] ?? 0,
                'Open leads': analytics['openLeads'] ?? 0,
                'Rating': analytics['rating'] ?? 0,
              }),
              const SizedBox(height: 12),
              const InfoStrip(
                icon: Icons.password_outlined,
                text:
                    'Admin se mile login ke baad provider apna password/profile update flow use karega.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProviderServices extends StatefulWidget {
  const ProviderServices({super.key, required this.api});

  final ApiClient api;

  @override
  State<ProviderServices> createState() => _ProviderServicesState();
}

class _ProviderServicesState extends State<ProviderServices> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final data = await widget.api.get('/providers/me/services');
    return (data['services'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final services = snapshot.data ?? [];
        return AppBackground(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CommunityHero(
                  name: 'Services',
                  title:
                      'Apni offerings publish karo aur moderation status track karo.'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CreateServiceSheet(
                      api: widget.api,
                      onSaved: () => setState(() => _future = _load())),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add service'),
              ),
              const SizedBox(height: 12),
              for (final service in services)
                PremiumCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.design_services_outlined,
                            color: AppTheme.deepRed),
                        title: Text((service['title'] ?? 'Service').toString(),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text([
                          (service['category'] ?? '').toString(),
                          (service['priceLabel'] ?? '').toString(),
                        ].where((value) => value.isNotEmpty).join(' | ')),
                        trailing: Chip(
                            label: Text(
                                (service['moderationStatus'] ?? 'pending')
                                    .toString())),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => CreateServiceSheet(
                                  api: widget.api,
                                  service: service,
                                  onSaved: () =>
                                      setState(() => _future = _load()),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.crimson,
                                side: BorderSide(
                                    color: AppTheme.crimson
                                        .withValues(alpha: .28)),
                              ),
                              onPressed: () => _deleteService(service),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (services.isEmpty)
                const EmptyState(
                    text: 'Aapki services abhi add nahi hain.',
                    icon: Icons.design_services_outlined),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteService(Map<String, dynamic> service) async {
    final id = (service['_id'] ?? service['id'] ?? '').toString();
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text(
            '${service['title'] ?? 'Service'} provider list se remove ho jayegi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.api.delete('/providers/me/services/$id');
    if (!mounted) return;
    setState(() => _future = _load());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Service deleted')),
    );
  }
}

class CreateServiceSheet extends StatefulWidget {
  const CreateServiceSheet({
    super.key,
    required this.api,
    required this.onSaved,
    this.service,
  });

  final ApiClient api;
  final VoidCallback onSaved;
  final Map<String, dynamic>? service;

  @override
  State<CreateServiceSheet> createState() => _CreateServiceSheetState();
}

class _CreateServiceSheetState extends State<CreateServiceSheet> {
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController();
  final _description = TextEditingController();
  late Future<List<CategoryItem>> _categories;
  bool _isActive = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    if (service != null) {
      _title.text = (service['title'] ?? '').toString();
      _category.text = (service['category'] ?? '').toString();
      _price.text = (service['priceLabel'] ?? '').toString();
      _duration.text = (service['durationLabel'] ?? '').toString();
      _description.text = (service['description'] ?? '').toString();
      _isActive = service['isActive'] != false;
    }
    _categories = _loadCategories();
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

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final payload = {
        'title': _title.text.trim(),
        'category': _category.text.trim(),
        'description': _description.text.trim().isEmpty
            ? 'Service details will be discussed on call.'
            : _description.text.trim(),
        'priceLabel': _price.text.trim(),
        'durationLabel': _duration.text.trim(),
        'packageType': 'standard',
        'includes': [],
        'isActive': _isActive,
      };
      final serviceId =
          (widget.service?['_id'] ?? widget.service?['id'] ?? '').toString();
      if (serviceId.isEmpty) {
        await widget.api.post('/providers/me/services', payload);
      } else {
        await widget.api.patch('/providers/me/services/$serviceId', payload);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: ListView(
        shrinkWrap: true,
        children: [
          SectionTitle(widget.service == null ? 'Add service' : 'Edit service'),
          FutureBuilder<List<CategoryItem>>(
            future: _categories,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];
              if (categories.isEmpty) {
                return TextField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                );
              }
              final selected =
                  categories.any((item) => item.name == _category.text)
                      ? _category.text
                      : null;
              return DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final category in categories)
                    DropdownMenuItem(
                        value: category.name, child: Text(category.name)),
                ],
                onChanged: (value) {
                  setState(() {
                    _category.text = value ?? '';
                    _title.clear();
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
                      const InputDecoration(labelText: 'Service title'),
                );
              }
              final selected =
                  services.contains(_title.text) ? _title.text : null;
              return DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Service',
                  helperText: 'Admin category ke according service select karo.',
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
                  if (value == '__custom__') {
                    _title.clear();
                  } else {
                    _title.text = value ?? '';
                  }
                  setState(() {});
                },
              );
            },
          ),
          if (_title.text.isEmpty) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              decoration:
                  const InputDecoration(labelText: 'New service title'),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
              controller: _price,
              decoration:
                  const InputDecoration(labelText: 'Rate / price label')),
          const SizedBox(height: 10),
          TextField(
              controller: _duration,
              decoration: const InputDecoration(labelText: 'Duration')),
          const SizedBox(height: 10),
          TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: const Text('Service available'),
            subtitle:
                const Text('Off karne par customer ko service hidden rahegi.'),
          ),
          const SizedBox(height: 14),
          FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy
                  ? 'Saving...'
                  : widget.service == null
                      ? 'Submit for moderation'
                      : 'Update service')),
        ],
      ),
    );
  }
}

class ProviderProfileEditSheet extends StatefulWidget {
  const ProviderProfileEditSheet({
    super.key,
    required this.api,
    required this.profile,
    required this.onSaved,
  });

  final ApiClient api;
  final Map<String, dynamic> profile;
  final VoidCallback onSaved;

  @override
  State<ProviderProfileEditSheet> createState() =>
      _ProviderProfileEditSheetState();
}

class _ProviderProfileEditSheetState extends State<ProviderProfileEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _businessName;
  late final TextEditingController _category;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _rate;
  late final TextEditingController _experience;
  late final TextEditingController _availability;
  late Future<List<String>> _categories;
  PickedImageUpload? _profileImage;
  PickedImageUpload? _coverImage;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = widget.profile['user'] is Map<String, dynamic>
        ? widget.profile['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    _name = TextEditingController(text: user['name']?.toString());
    _businessName =
        TextEditingController(text: widget.profile['businessName']?.toString());
    _category =
        TextEditingController(text: widget.profile['category']?.toString());
    _city = TextEditingController(text: widget.profile['city']?.toString());
    _address =
        TextEditingController(text: widget.profile['address']?.toString());
    _rate = TextEditingController(text: widget.profile['rate']?.toString());
    _experience = TextEditingController(
        text: (widget.profile['experienceYears'] ?? '').toString());
    _availability =
        TextEditingController(text: widget.profile['availability']?.toString());
    _categories = _loadCategories();
  }

  Future<List<String>> _loadCategories() async {
    try {
      final data = await widget.api.get('/categories');
      final names = (data['categories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((category) => (category['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      if (_category.text.trim().isNotEmpty &&
          !names.contains(_category.text.trim())) {
        names.insert(0, _category.text.trim());
      }
      return names;
    } catch (_) {
      return [];
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.api.put('/providers/me', {
        'name': _name.text.trim(),
        'businessName': _businessName.text.trim(),
        'category': _category.text.trim(),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'rate': _rate.text.trim(),
        'experienceYears': int.tryParse(_experience.text.trim()) ?? 0,
        'availability': _availability.text.trim().isEmpty
            ? 'Available'
            : _availability.text.trim(),
        if (_profileImage != null) 'profileImageFile': _profileImage!.toJson(),
        if (_coverImage != null) 'coverImageFile': _coverImage!.toJson(),
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          const SectionTitle('Edit provider profile'),
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Provider name')),
          const SizedBox(height: 10),
          TextField(
              controller: _businessName,
              decoration: const InputDecoration(labelText: 'Business name')),
          const SizedBox(height: 10),
          FutureBuilder<List<String>>(
            future: _categories,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];
              if (categories.isEmpty) {
                return TextField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                );
              }
              final selected =
                  categories.contains(_category.text) ? _category.text : null;
              return DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final category in categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) =>
                    setState(() => _category.text = value ?? ''),
              );
            },
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 10),
          TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 10),
          TextField(
              controller: _rate,
              decoration: const InputDecoration(labelText: 'Rate')),
          const SizedBox(height: 10),
          TextField(
              controller: _experience,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Experience years')),
          const SizedBox(height: 10),
          TextField(
              controller: _availability,
              decoration: const InputDecoration(labelText: 'Availability')),
          const SizedBox(height: 10),
          ImageUploadField(
            label: 'Profile photo',
            image: _profileImage,
            helperText: 'Provider public profile me use hogi.',
            onChanged: (image) => setState(() => _profileImage = image),
          ),
          const SizedBox(height: 10),
          ImageUploadField(
            label: 'Cover image',
            image: _coverImage,
            helperText: 'Business cover/banner image.',
            onChanged: (image) => setState(() => _coverImage = image),
          ),
          const SizedBox(height: 14),
          FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving...' : 'Save profile')),
        ],
      ),
    );
  }
}
