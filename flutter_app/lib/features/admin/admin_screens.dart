import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/api_config.dart';
import '../../core/models.dart';
import '../../shared/image_upload.dart';
import '../../shared/app_widgets.dart';
import '../providers/provider_screens.dart';
import '../taker/taker_catalog.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late Future<Map<String, dynamic>> _future;
  late Future<List<Map<String, dynamic>>> _ads;

  @override
  void initState() {
    super.initState();
    _future = widget.api.get('/admin/dashboard');
    _ads = _loadAds();
  }

  Future<List<Map<String, dynamic>>> _loadAds() async {
    try {
      final data = await widget.api.get('/ads', query: {
        'role': 'all',
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
        final stats = snapshot.data?['stats'] as Map<String, dynamic>? ?? {};
        return AppBackground(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            children: [
              const AdminPageTitle(
                title: 'Admin Dashboard',
                subtitle:
                    'Community operations, providers, ads and trust controls.',
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: ImagePromoBanner(
                  asset: AppAssets.adOne,
                  title: 'Manage community growth',
                  subtitle:
                      'Providers, takers, ads and trust signals in one admin surface.',
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _ads,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return RetryState(
                      onRetry: () => setState(() => _ads = _loadAds()),
                    );
                  }
                  final ads = snapshot.data ?? [];
                  if (ads.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LiveAdPreviewCard(ad: ads.first),
                  );
                },
              ),
              const SizedBox(height: 14),
              AdminMetricGrid(
                metrics: [
                  AdminMetric(
                    label: 'Total Users',
                    value: '${stats['totalUsers'] ?? 0}',
                    icon: Icons.groups_outlined,
                    color: AppTheme.saffron,
                    note: 'All roles',
                  ),
                  AdminMetric(
                    label: 'Providers',
                    value: '${stats['totalProviders'] ?? 0}',
                    icon: Icons.verified_user_outlined,
                    color: AppTheme.emerald,
                    note: 'Service partners',
                  ),
                  AdminMetric(
                    label: 'Open Requests',
                    value: '${stats['openRequests'] ?? 0}',
                    icon: Icons.assignment_outlined,
                    color: Colors.blue,
                    note: 'Need action',
                  ),
                  AdminMetric(
                    label: 'Pending',
                    value: '${stats['pendingProviders'] ?? 0}',
                    icon: Icons.pending_actions_outlined,
                    color: AppTheme.amber,
                    note: 'Verification',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const SectionTitle('Quick Actions'),
              AdminActionGrid(
                actions: [
                  AdminAction(
                    title: 'Provider Review',
                    subtitle: 'Verify provider accounts',
                    icon: Icons.person_add_alt,
                    color: AppTheme.saffron,
                    onTap: () {},
                  ),
                  AdminAction(
                    title: 'Open Bookings',
                    subtitle: '${stats['openRequests'] ?? 0} active requests',
                    icon: Icons.calendar_month_outlined,
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  AdminAction(
                    title: 'Services',
                    subtitle: '${stats['activeServices'] ?? 0} categories live',
                    icon: Icons.design_services_outlined,
                    color: Colors.purple,
                    onTap: () {},
                  ),
                  AdminAction(
                    title: 'Contacts',
                    subtitle: '${stats['contactLogs'] ?? 0} lead logs',
                    icon: Icons.call_outlined,
                    color: Colors.teal,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminProviders extends StatefulWidget {
  const AdminProviders({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminProviders> createState() => _AdminProvidersState();
}

class _AdminProvidersState extends State<AdminProviders> {
  late Future<List<ProviderProfile>> _future;
  final _search = TextEditingController();
  String _category = 'All Categories';
  String _status = 'All Status';
  bool _topRated = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ProviderProfile>> _load() async {
    final data = await widget.api.get('/admin/providers');
    return (data['profiles'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProviderProfile.fromJson)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProviderProfile>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppBackground(
            child: RetryState(onRetry: () => setState(() => _future = _load())),
          );
        }
        final providers = snapshot.data ?? [];
        final categories = [
          'All Categories',
          ...providers.map((provider) => provider.category).toSet().toList()
            ..sort(),
        ];
        final filtered = providers.where((provider) {
          final query = _search.text.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              provider.name.toLowerCase().contains(query) ||
              provider.phone.toLowerCase().contains(query) ||
              provider.category.toLowerCase().contains(query) ||
              provider.city.toLowerCase().contains(query);
          final matchesCategory = _category == 'All Categories' ||
              provider.category.toLowerCase() == _category.toLowerCase();
          final matchesStatus = _status == 'All Status' ||
              (_status == 'Verified' && provider.isApproved) ||
              (_status == 'Pending' && !provider.isApproved);
          return matchesSearch && matchesCategory && matchesStatus;
        }).toList()
          ..sort((a, b) => _topRated
              ? b.rating.compareTo(a.rating)
              : a.name.compareTo(b.name));
        final verified = providers.where((item) => item.isApproved).length;
        final pending = providers.length - verified;
        final active = providers
            .where((item) =>
                item.availability.toLowerCase().contains('available') ||
                item.availability.toLowerCase().contains('active'))
            .length;
        return AppBackground(
          child: RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                AdminPageTitle(
                  title: 'Provider Management',
                  subtitle: 'Manage, verify and monitor service providers.',
                  trailing: FilledButton.icon(
                    onPressed: _openCreateProvider,
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Add Provider'),
                  ),
                ),
                const SizedBox(height: 14),
                AdminMetricGrid(
                  metrics: [
                    AdminMetric(
                      label: 'Total Providers',
                      value: '${providers.length}',
                      icon: Icons.groups_outlined,
                      color: AppTheme.saffron,
                      note: 'Live accounts',
                    ),
                    AdminMetric(
                      label: 'Verified',
                      value: '$verified',
                      icon: Icons.verified_user_outlined,
                      color: AppTheme.emerald,
                      note: providers.isEmpty
                          ? '0% of total'
                          : '${((verified / providers.length) * 100).round()}% of total',
                    ),
                    AdminMetric(
                      label: 'Active',
                      value: '$active',
                      icon: Icons.person_outline,
                      color: Colors.blue,
                      note: 'Available providers',
                    ),
                    AdminMetric(
                      label: 'Pending',
                      value: '$pending',
                      icon: Icons.schedule_outlined,
                      color: AppTheme.amber,
                      note: pending == 0 ? 'All clear' : 'Needs attention',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const SectionTitle('Quick Actions'),
                AdminActionGrid(
                  actions: [
                    AdminAction(
                      title: 'Add Provider',
                      subtitle: 'Create new account',
                      icon: Icons.person_add_alt,
                      color: AppTheme.saffron,
                      onTap: _openCreateProvider,
                    ),
                    AdminAction(
                      title: 'Verification Queue',
                      subtitle: '$pending pending requests',
                      icon: Icons.verified_outlined,
                      color: Colors.purple,
                      onTap: () => setState(() => _status = 'Pending'),
                    ),
                    AdminAction(
                      title: 'Top Rated',
                      subtitle: 'Sort by rating',
                      icon: Icons.star_outline,
                      color: AppTheme.amber,
                      onTap: () => setState(() => _topRated = !_topRated),
                    ),
                    AdminAction(
                      title: 'Refresh',
                      subtitle: 'Reload live data',
                      icon: Icons.refresh,
                      color: Colors.teal,
                      onTap: () => setState(() => _future = _load()),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const SectionTitle('Search & Filters'),
                AdminFilterBar(
                  search: _search,
                  hint: 'Search providers by name, mobile...',
                  onSearchChanged: (_) => setState(() {}),
                  filters: [
                    AdminDropdownFilter(
                      value: categories.contains(_category)
                          ? _category
                          : 'All Categories',
                      values: categories,
                      onChanged: (value) =>
                          setState(() => _category = value ?? 'All Categories'),
                    ),
                    AdminDropdownFilter(
                      value: _status,
                      values: const ['All Status', 'Verified', 'Pending'],
                      onChanged: (value) =>
                          setState(() => _status = value ?? 'All Status'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AdminListHeader(
                  title: 'All Providers (${filtered.length})',
                  actionLabel:
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Loading'
                          : 'Newest First',
                ),
                const SizedBox(height: 10),
                for (final provider in filtered)
                  AdminProviderRow(
                    provider: provider,
                    api: widget.api,
                    onChanged: () => setState(() => _future = _load()),
                  ),
                if (filtered.isEmpty)
                  const EmptyState(
                      text: 'Provider list empty hai.',
                      icon: Icons.people_alt_outlined),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCreateProvider() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateProviderSheet(
        api: widget.api,
        onSaved: () => setState(() => _future = _load()),
      ),
    );
  }
}

class AdminPageTitle extends StatelessWidget {
  const AdminPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            height: 1.16,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
    if (trailing == null) return titleBlock;
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [titleBlock, const SizedBox(height: 12), trailing!],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        trailing!,
      ],
    );
  }
}

class AdminMetric {
  const AdminMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.note,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String note;
}

class AdminMetricGrid extends StatelessWidget {
  const AdminMetricGrid({super.key, required this.metrics});

  final List<AdminMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.95 : 2.2,
          ),
          itemBuilder: (context, index) => _AdminMetricCard(metrics[index]),
        );
      },
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard(this.metric);

  final AdminMetric metric;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: .13),
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, color: metric.color, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(metric.value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(metric.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: metric.color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminAction {
  const AdminAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class AdminActionGrid extends StatelessWidget {
  const AdminActionGrid({super.key, required this.actions});

  final List<AdminAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.7 : 2.5,
          ),
          itemBuilder: (context, index) => _AdminActionCard(actions[index]),
        );
      },
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard(this.action);

  final AdminAction action;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(action.icon, color: action.color, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(action.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({
    super.key,
    required this.search,
    required this.hint,
    required this.onSearchChanged,
    required this.filters,
  });

  final TextEditingController search;
  final String hint;
  final ValueChanged<String> onSearchChanged;
  final List<Widget> filters;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 330,
          child: TextField(
            controller: search,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: hint,
            ),
          ),
        ),
        ...filters,
      ],
    );
  }
}

class AdminDropdownFilter extends StatelessWidget {
  const AdminDropdownFilter({
    super.key,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(item)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class AdminListHeader extends StatelessWidget {
  const AdminListHeader({
    super.key,
    required this.title,
    this.actionLabel,
  });

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        if (actionLabel != null)
          Text(actionLabel!,
              style: const TextStyle(
                  color: AppTheme.muted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class AdminProviderRow extends StatelessWidget {
  const AdminProviderRow({
    super.key,
    required this.provider,
    required this.api,
    required this.onChanged,
  });

  final ProviderProfile provider;
  final ApiClient api;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final photo = provider.category.toLowerCase().contains('plumb')
        ? AppAssets.providerPlumber
        : provider.category.toLowerCase().contains('pandit')
            ? AppAssets.servicePandit
            : AppAssets.providerElectrician;
    final compact = MediaQuery.sizeOf(context).width < 720;
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminProviderIdentity(provider: provider, photo: photo),
                const SizedBox(height: 12),
                _AdminProviderMetrics(provider: provider),
                const SizedBox(height: 12),
                _AdminProviderActions(
                    provider: provider, api: api, onChanged: onChanged),
              ],
            )
          : Row(
              children: [
                Expanded(
                    flex: 3,
                    child: _AdminProviderIdentity(
                        provider: provider, photo: photo)),
                const SizedBox(width: 12),
                Expanded(
                    flex: 3, child: _AdminProviderMetrics(provider: provider)),
                const SizedBox(width: 12),
                SizedBox(
                    width: 210,
                    child: _AdminProviderActions(
                        provider: provider, api: api, onChanged: onChanged)),
              ],
            ),
    );
  }
}

class _AdminProviderIdentity extends StatelessWidget {
  const _AdminProviderIdentity({required this.provider, required this.photo});

  final ProviderProfile provider;
  final String photo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Image.asset(photo, width: 76, height: 76, fit: BoxFit.cover),
              Positioned(
                right: 5,
                bottom: 5,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color:
                        provider.isApproved ? AppTheme.emerald : AppTheme.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(provider.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  _AdminChip(
                    label: provider.isApproved ? 'Verified' : 'Pending',
                    color:
                        provider.isApproved ? AppTheme.emerald : AppTheme.amber,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _AdminTinyLine(
                  icon: serviceIconFor(provider.category),
                  text: provider.category),
              _AdminTinyLine(
                  icon: Icons.location_on_outlined,
                  text: provider.city.isEmpty ? 'Local area' : provider.city),
              _AdminTinyLine(
                  icon: Icons.call_outlined,
                  text: provider.phone.isEmpty
                      ? 'No phone added'
                      : provider.phone),
              Row(
                children: [
                  const Icon(Icons.star, color: AppTheme.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.rating.toStringAsFixed(1)} (${provider.reviewCount} reviews)',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminProviderMetrics extends StatelessWidget {
  const _AdminProviderMetrics({required this.provider});

  final ProviderProfile provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMetricBox(
            icon: Icons.reviews_outlined,
            label: 'Reviews',
            value: '${provider.reviewCount}',
            color: AppTheme.emerald,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniMetricBox(
            icon: Icons.currency_rupee,
            label: 'Rate',
            value: provider.rate.isEmpty ? 'Discuss' : provider.rate,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}

class _AdminProviderActions extends StatelessWidget {
  const _AdminProviderActions({
    required this.provider,
    required this.api,
    required this.onChanged,
  });

  final ProviderProfile provider;
  final ApiClient api;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdminChip(
          label: provider.availability.isEmpty
              ? 'Available'
              : provider.availability,
          color: AppTheme.emerald,
          centered: true,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => CreateProviderSheet(
              api: api,
              provider: provider,
              onSaved: onChanged,
            ),
          ),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProviderDetailsPage(provider: provider),
            ),
          ),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('View Profile'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.crimson,
            side: BorderSide(color: AppTheme.crimson.withValues(alpha: .28)),
          ),
          onPressed: () => _confirmDelete(context),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete provider?'),
        content: Text('${provider.name} ka account permanently delete hoga.'),
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
    if (confirmed != true || !context.mounted) return;
    await api.delete('/admin/providers/${provider.id}');
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider deleted')),
      );
    }
  }
}

class _MiniMetricBox extends StatelessWidget {
  const _MiniMetricBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        border: Border.all(color: color.withValues(alpha: .13)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  const _AdminChip({
    required this.label,
    required this.color,
    this.centered = false,
  });

  final String label;
  final Color color;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: centered ? Alignment.center : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _AdminTinyLine extends StatelessWidget {
  const _AdminTinyLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.navy, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.navy, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class CreateProviderSheet extends StatefulWidget {
  const CreateProviderSheet(
      {super.key, required this.api, required this.onSaved, this.provider});

  final ApiClient api;
  final VoidCallback onSaved;
  final ProviderProfile? provider;

  @override
  State<CreateProviderSheet> createState() => _CreateProviderSheetState();
}

class _CreateProviderSheetState extends State<CreateProviderSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _category = TextEditingController();
  final _city = TextEditingController(text: 'Bhilwara');
  final _rate = TextEditingController();
  late Future<List<String>> _categories;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final provider = widget.provider;
    if (provider != null) {
      _name.text = provider.name;
      _phone.text = provider.phone;
      _category.text = provider.category;
      _city.text = provider.city.isEmpty ? 'Bhilwara' : provider.city;
      _rate.text = provider.rate;
    }
    _categories = _loadCategories();
  }

  Future<List<String>> _loadCategories() async {
    try {
      final data = await widget.api.get('/admin/categories');
      final names = (data['categories'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .where((category) => category['isActive'] != false)
          .map((category) => (category['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();
      names.addAll(fallbackCategories.map((category) => category.name));
      names.addAll(takerServices.map((service) => service.name));
      final uniqueNames = <String>[];
      final seen = <String>{};
      for (final name in names) {
        if (seen.add(name.toLowerCase())) uniqueNames.add(name);
      }
      uniqueNames.sort();
      if (_category.text.trim().isNotEmpty &&
          !seen.contains(_category.text.trim().toLowerCase())) {
        uniqueNames.insert(0, _category.text.trim());
      }
      return uniqueNames.isEmpty ? _defaultProviderCategories() : uniqueNames;
    } catch (_) {
      return _defaultProviderCategories();
    }
  }

  List<String> _defaultProviderCategories() {
    final names = [
      ...fallbackCategories.map((category) => category.name),
      ...takerServices.map((service) => service.name),
    ];
    final uniqueNames = <String>[];
    final seen = <String>{};
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
        uniqueNames.add(trimmed);
      }
    }
    uniqueNames.sort();
    return uniqueNames;
  }

  Future<void> _save() async {
    if (_category.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final payload = {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'category': _category.text.trim(),
        'city': _city.text.trim(),
        'rate': _rate.text.trim(),
        'isApproved': true,
      };
      if (_password.text.trim().isNotEmpty) {
        payload['password'] = _password.text.trim();
      }
      if (widget.provider == null) {
        await widget.api.post('/admin/providers', payload);
      } else {
        await widget.api
            .put('/admin/providers/${widget.provider!.id}', payload);
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
          SectionTitle(widget.provider == null
              ? 'Provider login create'
              : 'Edit provider account'),
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Provider name')),
          const SizedBox(height: 10),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile')),
          const SizedBox(height: 10),
          TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                  labelText: widget.provider == null
                      ? 'Temporary password'
                      : 'New password (optional)')),
          const SizedBox(height: 10),
          FutureBuilder<List<String>>(
            future: _categories,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? _defaultProviderCategories();
              return _ServiceCategorySelector(
                controller: _category,
                categories: categories,
                loading: snapshot.connectionState == ConnectionState.waiting,
                onChanged: () => setState(() {}),
              );
            },
          ),
          const SizedBox(height: 10),
          TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 10),
          TextField(
              controller: _rate,
              decoration: const InputDecoration(labelText: 'Rate')),
          const SizedBox(height: 14),
          FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy
                  ? 'Saving...'
                  : widget.provider == null
                      ? 'Create account'
                      : 'Update account')),
        ],
      ),
    );
  }
}

class _ServiceCategorySelector extends StatelessWidget {
  const _ServiceCategorySelector({
    required this.controller,
    required this.categories,
    required this.onChanged,
    this.loading = false,
  });

  final TextEditingController controller;
  final List<String> categories;
  final VoidCallback onChanged;
  final bool loading;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ServiceCategoryPicker(
        categories: categories,
        initialValue: controller.text,
      ),
    );
    if (selected == null) return;
    controller.text = selected;
    onChanged();
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
        suffixIcon: loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: 'Select service',
                onPressed: () => _openPicker(context),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
      ),
    );
  }
}

class _ServiceCategoryPicker extends StatefulWidget {
  const _ServiceCategoryPicker({
    required this.categories,
    required this.initialValue,
  });

  final List<String> categories;
  final String initialValue;

  @override
  State<_ServiceCategoryPicker> createState() => _ServiceCategoryPickerState();
}

class _ServiceCategoryPickerState extends State<_ServiceCategoryPicker> {
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
          query.split(RegExp(r'\s+')).any(
              (part) => part.length > 1 && value.contains(part.toLowerCase()));
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
                  child: SectionTitle(
                    'Select service category',
                    subtitle: 'Type karke search karein ya list scroll karein.',
                  ),
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
                hintText: 'Electrician, plumber, AC...',
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

class AdminAds extends StatefulWidget {
  const AdminAds({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminAds> createState() => _AdminAdsState();
}

class _AdminAdsState extends State<AdminAds> {
  late Future<List<AdItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdItem>> _load() async {
    final data = await widget.api.get('/admin/ads');
    return (data['ads'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AdItem.fromJson)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppBackground(
            child: RetryState(onRetry: () => setState(() => _future = _load())),
          );
        }
        final ads = snapshot.data ?? [];
        final top = MediaQuery.paddingOf(context).top;
        return AppBackground(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, top + 14, 16, 110),
            children: [
              AdminPageTitle(
                title: 'Ads Management',
                subtitle:
                    'Create and publish promotional banners across the app.',
                trailing: FilledButton.icon(
                  onPressed: _openCreateAd,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add Ad'),
                ),
              ),
              const SizedBox(height: 14),
              AdminMetricGrid(
                metrics: [
                  AdminMetric(
                    label: 'Total Ads',
                    value: '${ads.length}',
                    icon: Icons.campaign_outlined,
                    color: AppTheme.saffron,
                    note: 'All placements',
                  ),
                  AdminMetric(
                    label: 'Active Ads',
                    value:
                        '${ads.where((ad) => ad.status.toLowerCase() == 'active').length}',
                    icon: Icons.play_circle_outline,
                    color: AppTheme.emerald,
                    note: 'Currently visible',
                  ),
                  AdminMetric(
                    label: 'Paused',
                    value:
                        '${ads.where((ad) => ad.status.toLowerCase() != 'active').length}',
                    icon: Icons.pause_circle_outline,
                    color: AppTheme.amber,
                    note: 'Needs review',
                  ),
                  const AdminMetric(
                    label: 'Placements',
                    value: '4',
                    icon: Icons.dashboard_customize_outlined,
                    color: Colors.blue,
                    note: 'Home, services, category',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const SectionTitle('Quick Actions'),
              AdminActionGrid(
                actions: [
                  AdminAction(
                    title: 'Add New Ad',
                    subtitle: 'Upload banner image',
                    icon: Icons.add_photo_alternate_outlined,
                    color: AppTheme.saffron,
                    onTap: _openCreateAd,
                  ),
                  AdminAction(
                    title: 'Dashboard Ads',
                    subtitle: 'Admin/provider/taker panels',
                    icon: Icons.space_dashboard_outlined,
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  AdminAction(
                    title: 'Category Ads',
                    subtitle: 'Service category placement',
                    icon: Icons.category_outlined,
                    color: Colors.purple,
                    onTap: () {},
                  ),
                  AdminAction(
                    title: 'Refresh',
                    subtitle: 'Reload live ads',
                    icon: Icons.refresh,
                    color: Colors.teal,
                    onTap: () => setState(() => _future = _load()),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AdminListHeader(title: 'All Ads (${ads.length})'),
              const SizedBox(height: 10),
              for (final ad in ads)
                _AdminAdRow(
                  ad: ad,
                  api: widget.api,
                  onChanged: () => setState(() => _future = _load()),
                ),
              if (ads.isEmpty)
                const EmptyState(
                    text: 'Ads abhi nahi hain.', icon: Icons.campaign_outlined),
            ],
          ),
        );
      },
    );
  }

  void _openCreateAd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateAdSheet(
        api: widget.api,
        onSaved: () => setState(() => _future = _load()),
      ),
    );
  }
}

class _AdminAdRow extends StatelessWidget {
  const _AdminAdRow({
    required this.ad,
    required this.api,
    required this.onChanged,
  });

  final AdItem ad;
  final ApiClient api;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final active = ad.status.toLowerCase() == 'active';
    final imageUrl = ApiConfig.mediaUrl(ad.imageUrl);
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 54,
                  child: imageUrl.isEmpty
                      ? Container(
                          color: AppTheme.saffron.withValues(alpha: .1),
                          child: const Icon(Icons.campaign_outlined,
                              color: AppTheme.saffron, size: 28),
                        )
                      : AppRemoteImage(
                          url: imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_) => Container(
                            color: AppTheme.saffron.withValues(alpha: .1),
                            child: const Icon(Icons.campaign_outlined,
                                color: AppTheme.saffron, size: 28),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                        ad.subtitle.isEmpty ? 'No subtitle added' : ad.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _AdminChip(
                          label: ad.status,
                          color: active ? AppTheme.emerald : AppTheme.amber,
                        ),
                        _AdminChip(
                          label: ad.placement,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CreateAdSheet(
                      api: api,
                      ad: ad,
                      onSaved: onChanged,
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
                        color: AppTheme.crimson.withValues(alpha: .28)),
                  ),
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete ad?'),
        content: Text('${ad.title} banner permanently delete hoga.'),
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
    if (confirmed != true || !context.mounted) return;
    await api.delete('/admin/ads/${ad.id}');
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad deleted')),
      );
    }
  }
}

class CreateAdSheet extends StatefulWidget {
  const CreateAdSheet({
    super.key,
    required this.api,
    required this.onSaved,
    this.ad,
  });

  final ApiClient api;
  final VoidCallback onSaved;
  final AdItem? ad;

  @override
  State<CreateAdSheet> createState() => _CreateAdSheetState();
}

class _CreateAdSheetState extends State<CreateAdSheet> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _imageUrl = TextEditingController();
  final _targetCategory = TextEditingController(text: 'all');
  PickedImageUpload? _image;
  final Set<String> _placements = {'home'};
  late Future<List<String>> _categories;
  String _audienceRole = 'all';
  String _status = 'Active';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _categories = _loadCategories();
    final ad = widget.ad;
    if (ad != null) {
      _title.text = ad.title;
      _subtitle.text = ad.subtitle;
      _imageUrl.text = ad.imageUrl;
      _targetCategory.text = ad.targetCategory;
      _placements
        ..clear()
        ..addAll(ad.placements.isNotEmpty ? ad.placements : [ad.placement]);
      if (_placements.isEmpty) _placements.add('all');
      _audienceRole = ad.audienceRole.isEmpty ? 'all' : ad.audienceRole;
      _status = ad.status.toLowerCase() == 'paused' ? 'Paused' : 'Active';
    }
  }

  Future<List<String>> _loadCategories() async {
    final names = <String>{
      'all',
      ...fallbackCategories.map((category) => category.name)
    };
    try {
      final data = await widget.api.get('/categories');
      for (final item in (data['categories'] as List? ?? [])) {
        if (item is Map<String, dynamic>) {
          final name = (item['name'] ?? '').toString().trim();
          if (name.isNotEmpty) names.add(name);
        }
      }
    } catch (_) {}
    if (_targetCategory.text.trim().isNotEmpty) {
      names.add(_targetCategory.text.trim());
    }
    return names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _togglePlacement(String value) {
    setState(() {
      if (value == 'all') {
        _placements
          ..clear()
          ..add('all');
      } else {
        _placements.remove('all');
        if (_placements.contains(value)) {
          _placements.remove(value);
        } else {
          _placements.add(value);
        }
        if (_placements.isEmpty) _placements.add('home');
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final payload = {
        'title': _title.text.trim(),
        'subtitle': _subtitle.text.trim(),
        'imageUrl': _imageUrl.text.trim(),
        if (_image != null) 'imageFile': _image!.toJson(),
        'placement': _placements.contains('all') ? 'all' : _placements.first,
        'placements':
            _placements.contains('all') ? ['all'] : _placements.toList(),
        'targetCategory': _targetCategory.text.trim().isEmpty
            ? 'all'
            : _targetCategory.text.trim(),
        'audienceRole': _audienceRole,
        'status': _status,
        'type': 'Home Rail',
        'ctaLabel': 'Know More',
      };
      if (widget.ad == null) {
        await widget.api.post('/admin/ads', payload);
      } else {
        await widget.api.patch('/admin/ads/${widget.ad!.id}', payload);
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
          SectionTitle(widget.ad == null ? 'Create ad' : 'Edit ad'),
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(
              controller: _subtitle,
              decoration: const InputDecoration(labelText: 'Subtitle')),
          const SizedBox(height: 10),
          TextField(
              controller: _imageUrl,
              decoration:
                  const InputDecoration(labelText: 'Image URL (optional)')),
          const SizedBox(height: 10),
          ImageUploadField(
            label: 'Upload ad image',
            image: _image,
            helperText: 'JPG, PNG or WEBP. Upload overrides Image URL.',
            onChanged: (image) => setState(() => _image = image),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<String>>(
            future: _categories,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const <String>[];
              final selected = categories.contains(_targetCategory.text)
                  ? _targetCategory.text
                  : null;
              if (categories.isEmpty) {
                return TextField(
                  controller: _targetCategory,
                  decoration:
                      const InputDecoration(labelText: 'Target category'),
                );
              }
              return DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Target category',
                  helperText: 'All = global ad; otherwise exact category only.',
                ),
                items: [
                  for (final category in categories)
                    DropdownMenuItem(value: category, child: Text(category))
                ],
                onChanged: (value) =>
                    setState(() => _targetCategory.text = value ?? 'all'),
              );
            },
          ),
          const SizedBox(height: 10),
          const Text('Show ad on',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                ['all', 'All pages'],
                ['home', 'Home'],
                ['services', 'Services'],
                ['category', 'Category detail'],
                ['dashboard', 'Dashboards'],
              ])
                FilterChip(
                  label: Text(item[1]),
                  selected: _placements.contains(item[0]),
                  onSelected: (_) => _togglePlacement(item[0]),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _audienceRole,
            decoration: const InputDecoration(labelText: 'Audience'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(
                  value: 'service_taker', child: Text('Service taker')),
              DropdownMenuItem(
                  value: 'service_provider', child: Text('Service provider')),
            ],
            onChanged: (value) =>
                setState(() => _audienceRole = value ?? 'all'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'Active', child: Text('Active')),
              DropdownMenuItem(value: 'Paused', child: Text('Paused')),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'Active'),
          ),
          const SizedBox(height: 14),
          FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy
                  ? 'Saving...'
                  : widget.ad == null
                      ? 'Create ad'
                      : 'Update ad')),
        ],
      ),
    );
  }
}
