import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/api_config.dart';
import '../../core/models.dart';
import '../../core/voice_search.dart';
import '../../shared/app_widgets.dart';
import '../booking/booking_screens.dart';
import '../notifications/notifications_page.dart';
import '../providers/provider_screens.dart';
import 'taker_catalog.dart';
import 'taker_ui.dart';

class TakerHome extends StatefulWidget {
  const TakerHome({super.key, required this.api, required this.user});

  final ApiClient api;
  final AppUser user;

  @override
  State<TakerHome> createState() => _TakerHomeState();
}

class _TakerHomeState extends State<TakerHome> {
  late Future<List<CategoryItem>> _categories;
  late Future<List<Map<String, dynamic>>> _ads;

  @override
  void initState() {
    super.initState();
    _categories = _loadCategories();
    _ads = _loadAds();
  }

  Future<List<Map<String, dynamic>>> _loadAds() async {
    try {
      final data = await widget.api.get('/ads', query: {
        'role': 'service_taker',
        'placement': 'home',
      });
      return (data['ads'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CategoryItem>> _loadCategories() async {
    try {
      final data = await widget.api.get('/categories');
      return (data['categories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CategoryItem.fromJson)
          .where((category) => category.name.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user.name.trim().isEmpty
        ? 'Aman'
        : widget.user.name.trim().split(' ').first;
    return RefreshIndicator(
      onRefresh: () async => setState(() {
        _categories = _loadCategories();
        _ads = _loadAds();
      }),
      child: FutureBuilder<List<CategoryItem>>(
        future: _categories,
        builder: (context, snapshot) {
          final categories = snapshot.data ?? const <CategoryItem>[];
          final mapped = categories.isEmpty
              ? groupedTakerServices()
              : categories
                  .map((item) => serviceByName(item.name))
                  .toSet()
                  .take(18)
                  .toList();
          final homeCategories = mapped.take(6).toList();
          final popularServices = mapped.take(4).toList();
          return TakerShellBackground(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 112),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: TakerWelcomePanel(
                    name: firstName,
                    onSearchTap: () => _openProviders(),
                    onNotificationTap: _openNotifications,
                    onVoiceSearchTap: _openVoiceProviderSearch,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _HomeQuickServices(
                    services: homeCategories,
                    onTap: _openService,
                    onAllServices: _openServices,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _ads,
                    builder: (context, snapshot) {
                      return _HomeBannerCarousel(
                        ads: snapshot.data ?? const [],
                        onBook: _openCreateRequest,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _HomeTrustStrip(),
                ),
                const SizedBox(height: 18),
                if (homeCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: EmptyState(
                      text: 'Abhi koi created service nahi hai.',
                      icon: Icons.design_services_outlined,
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TakerSectionHeader(
                      title: 'Category Services',
                      actionLabel: 'View All',
                      onAction: _openServices,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _HomeCategoryRail(
                      services: homeCategories,
                      onTap: _openService,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TakerSectionHeader(
                      title: 'Popular Services',
                      actionLabel: 'View All',
                      onAction: () => _openProviders(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: popularServices.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final item = popularServices[index];
                          return _MostBookedCard(
                            item: item,
                            onTap: () => _openProviders(item.name),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CustomServiceBanner(onTap: _openCreateRequest),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openProviders([String? category]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderSearch(
          api: widget.api,
          initialCategory: category,
        ),
      ),
    );
  }

  Future<void> _openVoiceProviderSearch() async {
    final text = await VoiceSearch.listen();
    if (!mounted || text == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderSearch(api: widget.api, initialQuery: text),
      ),
    );
  }

  void _openServices() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TakerServicesPage(api: widget.api)),
    );
  }

  void _openService(ServiceCatalogItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderSearch(
          api: widget.api,
          initialCategory: item.name,
          initialQuery: item.name,
        ),
      ),
    );
  }

  void _openCreateRequest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateRequestSheet(api: widget.api, onSaved: () {}),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(api: widget.api),
      ),
    );
  }
}

class TakerServicesPage extends StatefulWidget {
  const TakerServicesPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<TakerServicesPage> createState() => _TakerServicesPageState();
}

class _TakerServicesPageState extends State<TakerServicesPage> {
  String _selectedGroup = serviceCatalogGroups.first.name;
  late Future<List<CategoryItem>> _categories;
  late Future<List<Map<String, dynamic>>> _ads;

  @override
  void initState() {
    super.initState();
    _categories = _loadCategories();
    _ads = _loadAds();
  }

  Future<List<CategoryItem>> _loadCategories() async {
    try {
      final data = await widget.api.get('/categories');
      return (data['categories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CategoryItem.fromJson)
          .where((category) => category.name.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadAds() async {
    try {
      final data = await widget.api.get('/ads', query: {
        'role': 'service_taker',
        'placement': 'services',
      });
      return (data['ads'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<ServiceCatalogGroup> _groupsFromCategories(List<CategoryItem> categories) {
    if (categories.isEmpty) return serviceCatalogGroups;

    final backendByName = {
      for (final category in categories)
        category.name.trim().toLowerCase(): category,
    };
    final usedBackendNames = <String>{};
    final groups = <ServiceCatalogGroup>[];

    for (final defaultGroup in serviceCatalogGroups) {
      final backend = backendByName[defaultGroup.name.toLowerCase()];
      usedBackendNames.add(defaultGroup.name.toLowerCase());
      final services = backend == null || backend.serviceTypes.isEmpty
          ? defaultGroup.services
          : backend.serviceTypes.map(serviceByName).toList();
      groups.add(ServiceCatalogGroup(
        name: defaultGroup.name,
        subtitle: backend?.description.trim().isNotEmpty == true
            ? backend!.description
            : defaultGroup.subtitle,
        imageAsset: defaultGroup.imageAsset,
        icon: defaultGroup.icon,
        tint: defaultGroup.tint,
        services: services,
      ));
    }

    for (final category in categories) {
      final key = category.name.trim().toLowerCase();
      if (key.isEmpty || usedBackendNames.contains(key)) continue;
      final fallback = _catalogGroupFor(category.name);
      final serviceNames =
          category.serviceTypes.isEmpty ? [category.name] : category.serviceTypes;
      groups.add(ServiceCatalogGroup(
        name: category.name,
        subtitle: category.description.isEmpty
            ? 'Custom service group'
            : category.description,
        imageAsset: serviceAssetFor(category.name),
        icon: serviceIconFor(category.name),
        tint: fallback.tint,
        services: serviceNames.map(serviceByName).toList(),
      ));
    }

    return groups;
  }

  ServiceCatalogGroup _catalogGroupFor(String name) {
    final query = name.toLowerCase();
    return serviceCatalogGroups.firstWhere(
      (group) =>
          group.name.toLowerCase().contains(query) ||
          query.contains(group.name.toLowerCase()),
      orElse: () => serviceCatalogGroups.last,
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .52,
        minChildSize: .34,
        maxChildSize: .86,
        builder: (context, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const TakerSectionHeader(title: 'Choose Category'),
              ...serviceCatalogGroups.map(
                (group) => ListTile(
                  leading: Icon(
                    group.icon,
                    color: group.name == _selectedGroup ? AppTheme.saffron : null,
                  ),
                  title: Text(group.name),
                  subtitle: Text(group.subtitle),
                  trailing: group.name == _selectedGroup
                      ? const Icon(Icons.check, color: AppTheme.saffron)
                      : null,
                  onTap: () {
                    setState(() => _selectedGroup = group.name);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProviderSearch([String? query]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderSearch(api: widget.api, initialQuery: query),
      ),
    );
  }

  Future<void> _openVoiceProviderSearch() async {
    final text = await VoiceSearch.listen();
    if (!mounted || text == null) return;
    _openProviderSearch(text);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final serviceColumns = width < 520 ? 2 : 3;
    final categoryColumns = width < 680 ? 2 : 3;
    return FutureBuilder<List<CategoryItem>>(
      future: _categories,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <CategoryItem>[];
        final groups = _groupsFromCategories(categories);
        final selectedGroup = groups.firstWhere(
          (group) => group.name == _selectedGroup,
          orElse: () => groups.first,
        );
        final services = selectedGroup.services;
        return TakerShellBackground(
          child: RefreshIndicator(
            onRefresh: () async => setState(() {
              _categories = _loadCategories();
              _ads = _loadAds();
            }),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
              children: [
                TakerSearchBar(
                  compact: true,
                  onTap: () => _openProviderSearch(),
                  onVoiceTap: _openVoiceProviderSearch,
                ),
                const SizedBox(height: 18),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _ads,
                  builder: (context, snapshot) {
                    final ads = snapshot.data ?? [];
                    if (ads.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: _AdsCarousel(
                        ads: ads,
                        onTap: () => _openProviderSearch(),
                      ),
                    );
                  },
                ),
                _ServiceCategoryHero(
                  group: selectedGroup,
                  totalCategories: groups.length,
                  totalServices: groups.fold<int>(
                    0,
                    (sum, group) => sum + group.services.length,
                  ),
                ),
                const SizedBox(height: 22),
                TakerSectionHeader(
                  title: 'Service Categories',
                  actionLabel: '${groups.length} groups',
                  onAction: _openFilterSheet,
                ),
                _ServiceCategoryGrid(
                  groups: groups,
                  selected: selectedGroup.name,
                  columns: categoryColumns,
                  onTap: _openCategoryServices,
                ),
                const SizedBox(height: 22),
                TakerSectionHeader(
                  title: selectedGroup.name,
                  actionLabel: '${services.length} services',
                ),
                if (services.isEmpty)
                  const EmptyState(text: 'Abhi koi created service nahi hai.')
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: services.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: serviceColumns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: width < 520 ? .78 : .82,
                    ),
                    itemBuilder: (context, index) {
                      final item = services[index];
                      return ServiceImageCard(
                        item: item,
                        onTap: () => _openProviderSearchByCategory(item.name),
                      );
                    },
                  ),
                const SizedBox(height: 20),
                const _TrustBanner(),
                const SizedBox(height: 22),
                if (services.isNotEmpty) ...[
                  TakerSectionHeader(
                    title: 'Most Booked Services',
                    actionLabel: 'View All',
                    onAction: () => _openProviderSearchByCategory(
                      selectedGroup.services.first.name,
                    ),
                  ),
                  _HorizontalServiceCards(
                    services: services.take(6).toList(),
                    onTap: (item) => _openProviderSearchByCategory(item.name),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProviderSearchByCategory(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderSearch(
          api: widget.api,
          initialCategory: category,
          initialQuery: category,
        ),
      ),
    );
  }

  void _openCategoryServices(ServiceCatalogGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryServicesPage(api: widget.api, group: group),
      ),
    );
  }
}

class CategoryServicesPage extends StatelessWidget {
  const CategoryServicesPage({super.key, required this.api, required this.group});

  final ApiClient api;
  final ServiceCatalogGroup group;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 520 ? 2 : 3;
    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: TakerShellBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
          children: [
            _ServiceCategoryHero(
              group: group,
              totalCategories: 1,
              totalServices: group.services.length,
            ),
            const SizedBox(height: 18),
            TakerSectionHeader(
              title: '${group.name} Services',
              actionLabel: '${group.services.length} services',
            ),
            if (group.services.isEmpty)
              const EmptyState(text: 'Is category me service add nahi hai.')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.services.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: width < 520 ? .78 : .82,
                ),
                itemBuilder: (context, index) {
                  final item = group.services[index];
                  return ServiceImageCard(
                    item: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProviderSearch(
                          api: api,
                          initialCategory: item.name,
                          initialQuery: item.name,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class RequestsList extends StatefulWidget {
  const RequestsList({
    super.key,
    required this.api,
    this.admin = false,
    this.provider = false,
  });

  final ApiClient api;
  final bool admin;
  final bool provider;

  @override
  State<RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<RequestsList> {
  late Future<List<ServiceRequestItem>> _future;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ServiceRequestItem>> _load() async {
    if (widget.provider) {
      final assigned = await widget.api.get('/providers/me/requests');
      final open = await widget.api.get('/providers/me/open-requests');
      final merged = [
        ...(assigned['requests'] as List? ?? []),
        ...(open['requests'] as List? ?? []),
      ];
      final seen = <String>{};
      return merged
          .whereType<Map<String, dynamic>>()
          .map(ServiceRequestItem.fromJson)
          .where((item) => seen.add(item.id))
          .toList();
    }
    final path =
        widget.admin ? '/admin/requests' : '/service-takers/me/requests';
    final data = await widget.api.get(path);
    return (data['requests'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ServiceRequestItem.fromJson)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.admin || widget.provider) {
      return _CompactRequestsList(
        api: widget.api,
        future: _future,
        provider: widget.provider,
        onChanged: () => setState(() => _future = _load()),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _load()),
      child: FutureBuilder<List<ServiceRequestItem>>(
        future: _future,
        builder: (context, snapshot) {
          final liveItems = snapshot.data ?? [];
          final filteredItems = liveItems
              .where((item) => _bookingMatchesFilter(item, _statusFilter))
              .toList();
          return TakerShellBackground(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
              children: [
                _BookingTabs(
                  selected: _statusFilter,
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
                const SizedBox(height: 14),
                _BookingStats(items: liveItems),
                const SizedBox(height: 24),
                TakerSectionHeader(
                  title: 'My Bookings',
                  actionLabel: 'Latest',
                  onAction: () {},
                ),
                if (filteredItems.isEmpty)
                  const EmptyState(
                    text: 'Abhi koi booking nahi hai.',
                    icon: Icons.calendar_month_outlined,
                  )
                else
                  for (final item in filteredItems)
                    _LiveBookingCard(api: widget.api, item: item),
                const SizedBox(height: 18),
                _NewServiceBanner(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CreateRequestSheet(
                      api: widget.api,
                      onSaved: () => setState(() => _future = _load()),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _bookingMatchesFilter(ServiceRequestItem item, String filter) {
    final status = item.status.toLowerCase();
    return switch (filter) {
      'Upcoming' => status == 'open' || status == 'assigned',
      'Ongoing' => status == 'in_progress',
      'Completed' => status == 'completed',
      'Cancelled' => status == 'cancelled',
      _ => true,
    };
  }
}

class CreateRequestSheet extends StatefulWidget {
  const CreateRequestSheet({
    super.key,
    required this.api,
    required this.onSaved,
    this.initialCategory,
  });

  final ApiClient api;
  final VoidCallback onSaved;
  final String? initialCategory;

  @override
  State<CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<CreateRequestSheet> {
  late final TextEditingController _title;
  late final TextEditingController _category;
  final _city = TextEditingController(text: 'Bhilwara');
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _budget = TextEditingController();
  late Future<List<ProviderProfile>> _providers;
  late Future<List<String>> _categories;
  String _selectedProvider = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final category = widget.initialCategory?.trim().isNotEmpty == true
        ? widget.initialCategory!.trim()
        : 'AC Repair';
    _category = TextEditingController(text: category);
    _title = TextEditingController(text: '$category service');
    _categories = _loadCategories();
    _providers = _loadProviders();
  }

  Future<List<String>> _loadCategories() async {
    try {
      final data = await widget.api.get('/categories');
      final names = (data['categories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((category) => (category['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();
      names.addAll(fallbackCategories.map((category) => category.name));
      names.addAll(takerServices.map((service) => service.name));
      final unique = <String>[];
      final seen = <String>{};
      for (final name in names) {
        if (seen.add(name.toLowerCase())) unique.add(name);
      }
      unique.sort();
      return unique;
    } catch (_) {
      final names = [
        ...fallbackCategories.map((category) => category.name),
        ...takerServices.map((service) => service.name),
      ];
      final unique = <String>[];
      final seen = <String>{};
      for (final name in names) {
        if (seen.add(name.toLowerCase())) unique.add(name);
      }
      unique.sort();
      return unique;
    }
  }

  Future<List<ProviderProfile>> _loadProviders() async {
    final category = _category.text.trim();
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
              _takerProviderMatchesCategory(provider, category))
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

  void _selectCategory(String value) {
    final category = value.trim();
    if (category.isEmpty) return;
    setState(() {
      _category.text = category;
      if (_title.text.trim().isEmpty ||
          _title.text.trim().toLowerCase().endsWith('service')) {
        _title.text = '$category service';
      }
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
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'description': _description.text.trim().isEmpty
            ? 'Please assign a verified professional.'
            : _description.text.trim(),
        'budgetLabel': _budget.text.trim(),
        if (_selectedProvider.isNotEmpty) 'provider': _selectedProvider,
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const TakerSectionHeader(title: 'Book New Service'),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Request title'),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<String>>(
              future: _categories,
              builder: (context, snapshot) {
                return _TakerCategorySelector(
                  controller: _category,
                  categories: snapshot.data ?? const [],
                  loading: snapshot.connectionState == ConnectionState.waiting,
                  onSelected: _selectCategory,
                  onReload: _refreshProviders,
                );
              },
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<ProviderProfile>>(
              future: _providers,
              builder: (context, snapshot) {
                final providers = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _selectedProvider,
                  decoration: InputDecoration(
                    labelText: 'Choose provider',
                    helperText:
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading verified providers...'
                            : providers.isEmpty
                                ? 'No provider found. Booking will stay open.'
                                : 'Directly assign a verified provider.',
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('Any verified provider')),
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
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _budget,
              decoration: const InputDecoration(labelText: 'Budget label'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Work details'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.calendar_month),
              label: Text(_busy ? 'Saving...' : 'Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}

bool _takerProviderMatchesCategory(ProviderProfile provider, String category) {
  final terms = _takerCategoryTerms(category);
  if (terms.isEmpty) return true;
  final haystack = [
    provider.category,
    provider.businessName,
    provider.name,
    provider.rate,
  ].join(' ').toLowerCase();
  return terms.any(haystack.contains);
}

Set<String> _takerCategoryTerms(String category) {
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

class _TakerCategorySelector extends StatelessWidget {
  const _TakerCategorySelector({
    required this.controller,
    required this.categories,
    required this.onSelected,
    required this.onReload,
    this.loading = false,
  });

  final TextEditingController controller;
  final List<String> categories;
  final ValueChanged<String> onSelected;
  final VoidCallback onReload;
  final bool loading;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TakerCategoryPicker(
        categories: categories,
        initialValue: controller.text,
      ),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: loading ? null : () => _openPicker(context),
      decoration: InputDecoration(
        labelText: 'Service category',
        hintText: loading ? 'Loading services...' : 'Search or select service',
        prefixIcon: const Icon(Icons.design_services_outlined),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Reload providers',
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Select service',
                onPressed: () => _openPicker(context),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _TakerCategoryPicker extends StatefulWidget {
  const _TakerCategoryPicker({
    required this.categories,
    required this.initialValue,
  });

  final List<String> categories;
  final String initialValue;

  @override
  State<_TakerCategoryPicker> createState() => _TakerCategoryPickerState();
}

class _TakerCategoryPickerState extends State<_TakerCategoryPicker> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.categories;
    return widget.categories.where((category) {
      final value = category.toLowerCase();
      return value.contains(query) ||
          query
              .split(RegExp(r'\s+'))
              .any((part) => part.length > 1 && value.contains(part));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final filtered = _filtered;
    final query = _search.text.trim();
    final hasTypedOption = query.isNotEmpty &&
        !widget.categories
            .any((item) => item.toLowerCase() == query.toLowerCase());
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: TakerSectionHeader(title: 'Select Service Category'),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search services',
                hintText: 'Electrician, Plumber, AC...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty && !hasTypedOption
                  ? const EmptyState(
                      text: 'Is naam se service nahi mili.',
                      icon: Icons.search_off_outlined,
                    )
                  : ListView.separated(
                      itemCount: filtered.length + (hasTypedOption ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (hasTypedOption && index == 0) {
                          return ListTile(
                            leading: const Icon(Icons.add_circle_outline,
                                color: AppTheme.saffron),
                            title: Text('Use "$query"'),
                            subtitle: const Text('Custom service category'),
                            onTap: () => Navigator.pop(context, query),
                          );
                        }
                        final category =
                            filtered[index - (hasTypedOption ? 1 : 0)];
                        final selected = category.toLowerCase() ==
                            widget.initialValue.trim().toLowerCase();
                        return ListTile(
                          leading: Icon(
                            serviceIconFor(category),
                            color: selected ? AppTheme.saffron : AppTheme.muted,
                          ),
                          title: Text(category),
                          trailing: selected
                              ? const Icon(Icons.check_circle,
                                  color: AppTheme.emerald)
                              : const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, category),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdsCarousel extends StatefulWidget {
  const _AdsCarousel({required this.ads, required this.onTap});

  final List<Map<String, dynamic>> ads;
  final VoidCallback onTap;

  @override
  State<_AdsCarousel> createState() => _AdsCarouselState();
}

class _AdsCarouselState extends State<_AdsCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _AdsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads.length != widget.ads.length) {
      _index = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.ads.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _index = (_index + 1) % widget.ads.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).width < 520 ? 234.0 : 264.0;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.ads.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) => _LiveAdBanner(
                ad: widget.ads[index],
                onTap: widget.onTap,
              ),
            ),
          ),
          if (widget.ads.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.ads.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _index ? 18 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _index ? AppTheme.saffron : AppTheme.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveAdBanner extends StatelessWidget {
  const _LiveAdBanner({required this.ad, required this.onTap});

  final Map<String, dynamic> ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final title = (ad['title'] ?? 'Vipra Sewa Setu').toString();
    final subtitle =
        (ad['subtitle'] ?? ad['ctaLabel'] ?? 'Trusted local services')
            .toString();
    final imageUrl = ApiConfig.mediaUrl((ad['imageUrl'] ?? '').toString());
    final radius = BorderRadius.circular(22);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppTheme.navy.withValues(alpha: .13),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: narrow ? 196 : 224,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    AppRemoteImage(
                      url: imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_) => const _AdImageFallback(),
                    )
                  else
                    const _AdImageFallback(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: .62),
                          Colors.black.withValues(alpha: .22),
                          Colors.transparent,
                        ],
                        stops: const [0, .52, 1],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .82),
                        width: 1.2,
                      ),
                      borderRadius: radius,
                    ),
                  ),
                  Positioned(
                    left: narrow ? 16 : 20,
                    right: narrow ? 16 : 20,
                    top: narrow ? 14 : 18,
                    bottom: narrow ? 14 : 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MiniBadge(
                            icon: Icons.verified_outlined, text: 'Admin Ad'),
                        const Spacer(),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: narrow ? 265 : 360),
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: narrow ? 25 : 30,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: narrow ? 250 : 340),
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFFFF2E8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _AdCtaButton(
                          label: (ad['ctaLabel'] ?? 'Know More').toString(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdImageFallback extends StatelessWidget {
  const _AdImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18253F), Color(0xFFFF6A35)],
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 28),
          child: Icon(
            Icons.campaign_outlined,
            size: 96,
            color: Colors.white.withValues(alpha: .18),
          ),
        ),
      ),
    );
  }
}

class _AdCtaButton extends StatelessWidget {
  const _AdCtaButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.saffron,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel({
    required this.ads,
    required this.onBook,
  });

  final List<Map<String, dynamic>> ads;
  final VoidCallback onBook;

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  int get _itemCount => widget.ads.length + 1;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _HomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads.length != widget.ads.length) {
      _index = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_itemCount < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _index = (_index + 1) % _itemCount;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) {
      return _HeroBanner(onBook: widget.onBook);
    }
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return SizedBox(
      height: narrow ? 220 : 246,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _itemCount,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                if (index == 0) return _HeroBanner(onBook: widget.onBook);
                return _LiveAdBanner(
                  ad: widget.ads[index - 1],
                  onTap: widget.onBook,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _itemCount; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _index ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _index ? AppTheme.saffron : AppTheme.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Container(
      height: narrow ? 198 : 224,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF061B34), Color(0xFF0D223D), Color(0xFFFF8B19)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: .18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.homeServiceBannerV3,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF071C34),
                    const Color(0xFF071C34).withValues(alpha: .9),
                    const Color(0xFF071C34).withValues(alpha: .42),
                    Colors.transparent,
                  ],
                  stops: const [0, .42, .68, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(narrow ? 18 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Verified ',
                        style: TextStyle(color: Color(0xFFFF8B19)),
                      ),
                      TextSpan(text: 'Local\nProfessionals'),
                    ],
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: narrow ? 24 : 32,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: narrow ? 6 : 10),
                Text(
                  'Trusted experts, just a tap away!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFFFF2E8),
                    fontSize: narrow ? 12 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: narrow ? 8 : 14),
                Wrap(
                  spacing: narrow ? 6 : 10,
                  runSpacing: 5,
                  children: const [
                    _HeroCheck('Trusted'),
                    _HeroCheck('Verified'),
                    _HeroCheck('On-Time'),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: narrow ? 44 : 52,
                  child: FilledButton.icon(
                    onPressed: onBook,
                    icon: const Icon(Icons.arrow_forward, size: 22),
                    label: const Text('Book Service'),
                    style: FilledButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: narrow ? 16 : 24),
                      textStyle: TextStyle(
                        fontSize: narrow ? 15 : 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeQuickServices extends StatelessWidget {
  const _HomeQuickServices({
    required this.services,
    required this.onTap,
    required this.onAllServices,
  });

  final List<ServiceCatalogItem> services;
  final ValueChanged<ServiceCatalogItem> onTap;
  final VoidCallback onAllServices;

  @override
  Widget build(BuildContext context) {
    final visible = services.take(5).toList();
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Row(
        children: [
          for (final item in visible)
            Expanded(
              child: _QuickServiceButton(
                item: item,
                onTap: () => onTap(item),
              ),
            ),
          Expanded(
            child: _QuickServiceButton(
              label: 'All Services',
              icon: Icons.grid_view_rounded,
              onTap: onAllServices,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickServiceButton extends StatelessWidget {
  const _QuickServiceButton({
    required this.onTap,
    this.item,
    this.label,
    this.icon,
  });

  final ServiceCatalogItem? item;
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = label ?? item?.name ?? 'Service';
    final shortTitle = _quickServiceLabel(title);
    final iconData = icon ?? _quickServiceIconFor(title);
    final color = _quickServiceColorFor(title);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: .18)),
              ),
              child: Icon(iconData, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              shortTitle,
              maxLines: 2,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.05,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _quickServiceLabel(String value) {
  final text = value.toLowerCase();
  if (text.contains('electric')) return 'Electrician';
  if (text.contains('plumb')) return 'Plumber';
  if (text.contains('clean')) return 'Cleaning';
  if (text.contains('carpent')) return 'Carpenter';
  if (text.contains('paint')) return 'Painter';
  if (text.contains('ac')) return 'AC Repair';
  if (text.contains('all')) return 'All\nServices';
  return value;
}

IconData _quickServiceIconFor(String value) {
  final text = value.toLowerCase();
  if (text.contains('electric')) return Icons.electrical_services;
  if (text.contains('plumb')) return Icons.plumbing;
  if (text.contains('clean')) return Icons.cleaning_services;
  if (text.contains('carpent')) return Icons.carpenter;
  if (text.contains('paint')) return Icons.format_paint;
  if (text.contains('ac')) return Icons.ac_unit;
  if (text.contains('all')) return Icons.grid_view_rounded;
  return serviceIconFor(value);
}

Color _quickServiceColorFor(String value) {
  final text = value.toLowerCase();
  if (text.contains('electric')) return AppTheme.saffron;
  if (text.contains('plumb')) return const Color(0xFF2176FF);
  if (text.contains('clean')) return AppTheme.emerald;
  if (text.contains('carpent')) return const Color(0xFFC4661F);
  if (text.contains('driver') || text.contains('mover')) {
    return const Color(0xFF7C4DFF);
  }
  return AppTheme.saffron;
}

class _HeroCheck extends StatelessWidget {
  const _HeroCheck(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle,
            color: const Color(0xFFFF8B19), size: narrow ? 16 : 18),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: narrow ? 12 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HomeTrustStrip extends StatelessWidget {
  const _HomeTrustStrip();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.saffron,
          fontWeight: FontWeight.w900,
          height: 1.2,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFFFC5AD))),
          const SizedBox(width: 8),
          Flexible(
            flex: 12,
            child: Text(
              '✦ समाज को जोड़ने वाला विश्वसनीय डिजिटल मंच ✦',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: style,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Color(0xFFFFC5AD))),
        ],
      ),
    );
  }
}

class _HomeCategoryRail extends StatelessWidget {
  const _HomeCategoryRail({required this.services, required this.onTap});

  final List<ServiceCatalogItem> services;
  final ValueChanged<ServiceCatalogItem> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = services[index];
          return SizedBox(
            width: 160,
            child: ServiceImageCard(item: item, onTap: () => onTap(item)),
          );
        },
      ),
    );
  }
}

class _MostBookedCard extends StatelessWidget {
  const _MostBookedCard({required this.item, required this.onTap});

  final ServiceCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: PremiumCard(
        padding: const EdgeInsets.all(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  serviceAssetFor(item.name),
                  height: 82,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.verified_outlined,
                      color: AppTheme.emerald, size: 18),
                  SizedBox(width: 4),
                  Text('Verified provider'),
                  Spacer(),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFE9F8EF),
                    child: Icon(Icons.call, color: AppTheme.success),
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

class _CustomServiceBanner extends StatelessWidget {
  const _CustomServiceBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEFE2), Color(0xFFFFDCC2)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD7C6)),
      ),
      child: Flex(
        direction: compact ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment:
            compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          const Icon(Icons.health_and_safety,
              color: AppTheme.saffron, size: 54),
          SizedBox(width: compact ? 0 : 16, height: compact ? 12 : 0),
          if (compact)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need a custom service?',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 5),
                Text("Let us know your requirement and we'll help you.",
                    style: TextStyle(
                        color: AppTheme.muted, fontWeight: FontWeight.w800)),
              ],
            )
          else
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need a custom service?',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text("Let us know your requirement and we'll help you.",
                      style: TextStyle(
                          color: AppTheme.muted, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          SizedBox(width: compact ? 0 : 16, height: compact ? 14 : 0),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            label: const Text('Request Now'),
          ),
          if (!compact) ...[
            const SizedBox(width: 16),
            Image.asset(AppAssets.providerElectrician,
                height: 86, width: 86, fit: BoxFit.cover),
          ],
        ],
      ),
    );
  }
}

class _ServiceCategoryHero extends StatelessWidget {
  const _ServiceCategoryHero({
    required this.group,
    required this.totalCategories,
    required this.totalServices,
  });

  final ServiceCatalogGroup group;
  final int totalCategories;
  final int totalServices;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: .06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Flex(
        direction: compact ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment:
            compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(group.imageAsset, fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.white,
                      child: Icon(group.icon,
                          color: AppTheme.saffron, size: 19),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: compact ? 0 : 14, height: compact ? 12 : 0),
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  group.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    group.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(width: compact ? 0 : 12, height: compact ? 14 : 0),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryMetric(
                icon: Icons.category_outlined,
                label: '$totalCategories categories',
              ),
              _CategoryMetric(
                icon: Icons.design_services_outlined,
                label: '$totalServices services',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryMetric extends StatelessWidget {
  const _CategoryMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppTheme.saffron),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCategoryGrid extends StatelessWidget {
  const _ServiceCategoryGrid({
    required this.groups,
    required this.selected,
    required this.columns,
    required this.onTap,
  });

  final List<ServiceCatalogGroup> groups;
  final String selected;
  final int columns;
  final ValueChanged<ServiceCatalogGroup> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: columns == 2 ? .86 : 1.08,
      ),
      itemBuilder: (context, index) {
        final group = groups[index];
        final isSelected = group.name == selected;
        return InkWell(
          onTap: () => onTap(group),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? AppTheme.saffron : AppTheme.line,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.navy.withValues(alpha: isSelected ? .12 : .06),
                  blurRadius: isSelected ? 22 : 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.75,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          group.imageAsset,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.navy.withValues(alpha: .18),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(group.icon,
                                    color: AppTheme.saffron, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${group.services.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(group.icon, color: AppTheme.saffron, size: 18),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${group.services.length} services',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEFE2), Color(0xFFFFDDBF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD7C6)),
      ),
      child: Flex(
        direction: compact ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment:
            compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          const Icon(Icons.health_and_safety_outlined,
              color: AppTheme.saffron, size: 54),
          SizedBox(width: compact ? 0 : 16, height: compact ? 12 : 0),
          if (compact)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verified Local Professionals',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 5),
                Text('Background verified, on-time service, quality assured.',
                    style: TextStyle(
                        color: AppTheme.muted, fontWeight: FontWeight.w800)),
              ],
            )
          else
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verified Local Professionals',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text('Background verified, on-time service, quality assured.',
                      style: TextStyle(
                          color: AppTheme.muted, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          if (!compact) const SizedBox(width: 16),
          if (!compact)
            Image.asset(AppAssets.providerElectrician,
                height: 92, width: 92, fit: BoxFit.cover),
        ],
      ),
    );
  }
}

class _HorizontalServiceCards extends StatelessWidget {
  const _HorizontalServiceCards({required this.services, required this.onTap});

  final List<ServiceCatalogItem> services;
  final ValueChanged<ServiceCatalogItem> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = services[index];
          return SizedBox(
            width: 178,
            child: PremiumCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () => onTap(item),
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.asset(serviceAssetFor(item.name),
                          height: 92,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.verified_outlined,
                                  color: AppTheme.emerald, size: 16),
                              SizedBox(width: 4),
                              Text('Live',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800)),
                              Spacer(),
                              Text('Verified',
                                  style: TextStyle(
                                      color: AppTheme.saffron,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingTabs extends StatelessWidget {
  const _BookingTabs({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (Icons.grid_view_rounded, 'All'),
      (Icons.calendar_month, 'Upcoming'),
      (Icons.schedule, 'Ongoing'),
      (Icons.check_circle_outline, 'Completed'),
      (Icons.cancel_outlined, 'Cancelled'),
    ];
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final active = tab.$2 == selected;
          return ChoiceChip(
            selected: active,
            showCheckmark: false,
            avatar: Icon(tab.$1,
                color: active ? Colors.white : AppTheme.ink, size: 18),
            label: Text(index == 0 ? 'All Bookings' : tab.$2),
            onSelected: (_) => onChanged(tab.$2),
            backgroundColor: Colors.white,
            selectedColor: AppTheme.saffron,
            labelStyle: TextStyle(
              color: active ? Colors.white : AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            side: BorderSide(color: active ? AppTheme.saffron : AppTheme.line),
          );
        },
      ),
    );
  }
}

class _BookingStats extends StatelessWidget {
  const _BookingStats({required this.items});

  final List<ServiceRequestItem> items;

  @override
  Widget build(BuildContext context) {
    final upcoming = items
        .where((item) =>
            item.status.toLowerCase() == 'open' ||
            item.status.toLowerCase() == 'assigned')
        .length;
    final ongoing = items
        .where((item) => item.status.toLowerCase() == 'in_progress')
        .length;
    final completed =
        items.where((item) => item.status.toLowerCase() == 'completed').length;
    final cancelled =
        items.where((item) => item.status.toLowerCase() == 'cancelled').length;
    final stats = [
      (Icons.work_outline, 'Total Bookings', items.length, AppTheme.saffron),
      (Icons.event_available, 'Upcoming', upcoming, Colors.blue),
      (Icons.play_circle_outline, 'Ongoing', ongoing, AppTheme.emerald),
      (Icons.check_circle_outline, 'Completed', completed, Colors.purple),
      (Icons.cancel_outlined, 'Cancelled', cancelled, AppTheme.crimson),
    ];
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return SizedBox(
            width: 154,
            child: PremiumCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: stat.$4.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(stat.$1, color: stat.$4, size: 21),
                      ),
                      const SizedBox(width: 10),
                      Text('${stat.$3}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(stat.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LiveBookingCard extends StatelessWidget {
  const _LiveBookingCard({required this.api, required this.item});

  final ApiClient api;
  final ServiceRequestItem item;

  @override
  Widget build(BuildContext context) {
    final service = serviceByName(item.category);
    return _BookingCardFrame(
      asset: service.asset,
      timeLabel: item.status == 'open' ? 'Waiting for provider' : item.status,
      title: item.title,
      provider: 'Provider assignment pending',
      rating: service.rating,
      location: item.city.isEmpty ? 'Bhilwara, Rajasthan' : item.city,
      bookingId: item.id.isEmpty
          ? '#VS-NEW'
          : '#${item.id.substring(0, item.id.length > 8 ? 8 : item.id.length)}',
      status: item.status,
      budgetLabel: item.budgetLabel,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailsPage(api: api, item: item),
        ),
      ),
    );
  }
}

class _BookingCardFrame extends StatelessWidget {
  const _BookingCardFrame({
    required this.asset,
    required this.timeLabel,
    required this.title,
    required this.provider,
    required this.rating,
    required this.location,
    required this.bookingId,
    required this.status,
    required this.budgetLabel,
    this.onTap,
  });

  final String asset;
  final String timeLabel;
  final String title;
  final String provider;
  final double rating;
  final String location;
  final String bookingId;
  final String status;
  final String budgetLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 560;
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.asset(asset,
              width: narrow ? double.infinity : 190,
              height: narrow ? 170 : 148,
              fit: BoxFit.cover),
          Positioned(
            left: 10,
            bottom: 10,
            child: _StatusPill(text: _prettyStatus(status)),
          ),
        ],
      ),
    );
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Flex(
          direction: narrow ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            image,
            SizedBox(width: narrow ? 0 : 16, height: narrow ? 14 : 0),
            if (narrow)
              _BookingCardDetails(
                timeLabel: timeLabel,
                title: title,
                provider: provider,
                rating: rating,
                location: location,
                bookingId: bookingId,
                status: status,
                budgetLabel: budgetLabel,
                onTap: onTap,
              )
            else
              Expanded(
                child: _BookingCardDetails(
                  timeLabel: timeLabel,
                  title: title,
                  provider: provider,
                  rating: rating,
                  location: location,
                  bookingId: bookingId,
                  status: status,
                  budgetLabel: budgetLabel,
                  onTap: onTap,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _prettyStatus(String value) {
    return value.replaceAll('_', ' ').trim().isEmpty
        ? 'Upcoming'
        : value.replaceAll('_', ' ');
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = text.toLowerCase().contains('progress')
        ? AppTheme.success
        : AppTheme.saffron;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _BookingCardDetails extends StatelessWidget {
  const _BookingCardDetails({
    required this.timeLabel,
    required this.title,
    required this.provider,
    required this.rating,
    required this.location,
    required this.bookingId,
    required this.status,
    required this.budgetLabel,
    this.onTap,
  });

  final String timeLabel;
  final String title;
  final String provider;
  final double rating;
  final String location;
  final String bookingId;
  final String status;
  final String budgetLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month_outlined,
                size: 18, color: AppTheme.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                timeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.muted, fontWeight: FontWeight.w800),
              ),
            ),
            if (budgetLabel.isNotEmpty)
              Text(
                budgetLabel,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              )
            else
              const Icon(Icons.more_vert),
          ],
        ),
        const SizedBox(height: 8),
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            const CircleAvatar(
              radius: 11,
              backgroundImage: AssetImage(AppAssets.providerElectrician),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _RatingBadgePill(rating: rating),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 18, color: AppTheme.muted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.muted, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Booking ID: $bookingId',
          style: const TextStyle(
              color: AppTheme.muted, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(status.toLowerCase() == 'in_progress'
                ? Icons.location_on_outlined
                : Icons.visibility_outlined),
            label: Text(status.toLowerCase() == 'in_progress'
                ? 'Track Live'
                : 'View Details'),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${rating.toStringAsFixed(1)} ★',
        style: const TextStyle(
            color: AppTheme.success, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RatingBadgePill extends StatelessWidget {
  const _RatingBadgePill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
                color: AppTheme.success, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.star, color: AppTheme.success, size: 14),
        ],
      ),
    );
  }
}

class _NewServiceBanner extends StatelessWidget {
  const _NewServiceBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9D9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Flex(
        direction: narrow ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment:
            narrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          const Icon(Icons.event_available, color: AppTheme.saffron, size: 42),
          SizedBox(width: narrow ? 0 : 16, height: narrow ? 12 : 0),
          if (narrow)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need a New Service?',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Book trusted professionals in just a few taps.',
                    style: TextStyle(color: AppTheme.muted)),
              ],
            )
          else
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need a New Service?',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Book trusted professionals in just a few taps.',
                      style: TextStyle(color: AppTheme.muted)),
                ],
              ),
            ),
          if (!narrow) const Spacer(),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            label: const Text('Book New Service'),
          ),
        ],
      ),
    );
  }
}

class _CompactRequestsList extends StatelessWidget {
  const _CompactRequestsList({
    required this.api,
    required this.future,
    required this.onChanged,
    this.provider = false,
  });

  final ApiClient api;
  final Future<List<ServiceRequestItem>> future;
  final VoidCallback onChanged;
  final bool provider;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServiceRequestItem>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return AppBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            children: [
              for (final item in items)
                provider
                    ? _ProviderRequestCard(
                        api: api,
                        item: item,
                        onChanged: onChanged,
                      )
                    : _LiveBookingCard(api: api, item: item),
              if (items.isEmpty)
                const EmptyState(
                  text: 'Requests abhi empty hain.',
                  icon: Icons.assignment_late_outlined,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProviderRequestCard extends StatelessWidget {
  const _ProviderRequestCard({
    required this.api,
    required this.item,
    required this.onChanged,
  });

  final ApiClient api;
  final ServiceRequestItem item;
  final VoidCallback onChanged;

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _whatsAppPhone(String value) {
    final digits = _digits(value);
    if (digits.startsWith('91') && digits.length > 10) return digits;
    return '91$digits';
  }

  Future<void> _call() async {
    final phone = _digits(item.serviceTakerPhone);
    if (phone.isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _whatsapp() async {
    if (item.serviceTakerPhone.trim().isEmpty) return;
    await launchUrl(
      Uri.parse('https://wa.me/${_whatsAppPhone(item.serviceTakerPhone)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _claim(BuildContext context) async {
    await api.patch('/providers/me/open-requests/${item.id}/claim', {});
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted')),
      );
    }
  }

  Future<void> _updateStatus(
      BuildContext context, String status, String defaultNote) async {
    final note = await _statusNoteDialog(context, status, defaultNote);
    if (note == null) return;
    await api.patch('/providers/me/requests/${item.id}/status', {
      'status': status,
      'note': note,
    });
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Status updated: ${status.replaceAll('_', ' ')}')),
      );
    }
  }

  Future<String?> _statusNoteDialog(
      BuildContext context, String status, String defaultNote) async {
    final note = TextEditingController(text: defaultNote);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update ${status.replaceAll('_', ' ')}'),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Customer update / reason / ETA',
            hintText: 'Example: I will reach in 30 minutes',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, note.text.trim()),
              child: const Text('Update')),
        ],
      ),
    );
  }

  String _shortDate(String value) {
    if (value.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = item.status.toLowerCase();
    final customer =
        item.serviceTakerName.isEmpty ? 'Service taker' : item.serviceTakerName;
    final preferredDate = _shortDate(item.preferredDate);
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              _StatusPill(text: status.replaceAll('_', ' ')),
            ],
          ),
          const SizedBox(height: 8),
          Text('${item.category} | ${item.city}',
              style: const TextStyle(
                  color: AppTheme.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Customer: $customer',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          if (item.serviceTakerPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Mobile: ${item.serviceTakerPhone}',
                style: const TextStyle(
                    color: AppTheme.muted, fontWeight: FontWeight.w700)),
          ],
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.description,
                style: const TextStyle(height: 1.35)),
          ],
          const SizedBox(height: 14),
          Text(
            'Booking details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          _ProviderBookingDetailRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: item.address,
          ),
          _ProviderBookingDetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Preferred date',
            value: preferredDate,
          ),
          _ProviderBookingDetailRow(
            icon: Icons.schedule_outlined,
            label: 'Preferred time',
            value: item.preferredTimeSlot,
          ),
          _ProviderBookingDetailRow(
            icon: Icons.currency_rupee,
            label: 'Budget',
            value: item.budgetLabel,
          ),
          if (item.imageUrl.isNotEmpty) ...[
            const _ProviderBookingDetailRow(
              icon: Icons.image_outlined,
              label: 'Issue photo',
              value: 'Attached',
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: AppRemoteImage(
                  url: ApiConfig.mediaUrl(item.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: item.serviceTakerPhone.isEmpty ? null : _call,
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: item.serviceTakerPhone.isEmpty ? null : _whatsapp,
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (status == 'open')
                FilledButton.icon(
                  onPressed: () => _claim(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Accept'),
                ),
              if (status == 'assigned')
                FilledButton.icon(
                  onPressed: () => _updateStatus(
                    context,
                    'in_progress',
                    'Work started. I will update you shortly.',
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Start'),
                ),
              if (status == 'in_progress')
                FilledButton.icon(
                  onPressed: () => _updateStatus(
                    context,
                    'completed',
                    'Work completed. Please share your rating.',
                  ),
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Complete'),
                ),
              if (status == 'assigned' || status == 'in_progress')
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.crimson,
                    side: BorderSide(
                        color: AppTheme.crimson.withValues(alpha: .28)),
                  ),
                  onPressed: () => _updateStatus(
                    context,
                    'cancelled',
                    'Unable to serve this request right now.',
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderBookingDetailRow extends StatelessWidget {
  const _ProviderBookingDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.saffron),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
