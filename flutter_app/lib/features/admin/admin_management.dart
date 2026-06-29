import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/api_config.dart';
import '../../shared/app_widgets.dart';
import '../../shared/image_upload.dart';
import 'admin_screens.dart';

class AdminManagementHub extends StatelessWidget {
  const AdminManagementHub({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AdminTool('Category Management', 'Add, edit, delete service categories',
          Icons.category_outlined, CategoryManagementPage(api: api)),
      _AdminTool('Ads Management', 'Create and publish banners in the app',
          Icons.campaign_outlined, AdminAds(api: api)),
      _AdminTool('Booking Management', 'Assign provider and update status',
          Icons.assignment_outlined, BookingManagementPage(api: api)),
      _AdminTool('Complaint Management', 'Resolve customer/provider tickets',
          Icons.report_problem_outlined, ComplaintManagementPage(api: api)),
      const _AdminTool(
          'Announcements',
          'Festival greetings and emergency alerts',
          Icons.campaign_outlined,
          AnnouncementPage()),
      const _AdminTool(
          'Reports & Analytics',
          'Growth, bookings and provider performance',
          Icons.analytics_outlined,
          ReportsAnalyticsPage()),
      const _AdminTool('Settings', 'Language, notification and app controls',
          Icons.settings_outlined, SettingsPage()),
    ];

    return AppBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.paddingOf(context).bottom + 120,
        ),
        children: [
          const AdminPageTitle(
            title: 'Management',
            subtitle: 'Control platform operations from one admin dashboard.',
          ),
          const SizedBox(height: 14),
          AdminActionGrid(
            actions: [
              for (final item in items)
                AdminAction(
                  title: item.title,
                  subtitle: item.subtitle,
                  icon: item.icon,
                  color: _toolColor(item.title),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => item.screen)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const InfoStrip(
            icon: Icons.admin_panel_settings_outlined,
            text:
                'Use these tools to manage categories, ads, bookings, reports, announcements and settings.',
          ),
        ],
      ),
    );
  }

  Color _toolColor(String title) {
    if (title.contains('Ads')) return AppTheme.saffron;
    if (title.contains('Booking')) return Colors.blue;
    if (title.contains('Complaint')) return AppTheme.crimson;
    if (title.contains('Report')) return Colors.purple;
    if (title.contains('Settings')) return AppTheme.navy;
    return AppTheme.emerald;
  }
}

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _services = TextEditingController();
  PickedImageUpload? _image;
  Map<String, dynamic>? _editingCategory;
  late Future<List<Map<String, dynamic>>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final data = await widget.api.get('/admin/categories');
    return (data['categories'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final payload = {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'serviceTypes': _serviceTypeList(),
        if (_image != null) 'imageFile': _image!.toJson(),
        'isActive': true,
      };
      final editId = (_editingCategory?['_id'] ?? _editingCategory?['id'] ?? '')
          .toString();
      if (editId.isEmpty) {
        await widget.api.post('/admin/categories', payload);
      } else {
        await widget.api.put('/admin/categories/$editId', payload);
      }
      _clearForm();
      setState(() => _future = _load());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startEdit(Map<String, dynamic> category) {
    setState(() {
      _editingCategory = category;
      _name.text = (category['name'] ?? '').toString();
      _description.text = (category['description'] ?? '').toString();
      _services.text = ((category['serviceTypes'] as List? ?? [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .join('\n'));
      _image = null;
    });
  }

  void _clearForm() {
    _editingCategory = null;
    _name.clear();
    _description.clear();
    _services.clear();
    _image = null;
  }

  List<String> _serviceTypeList() {
    return _services.text
        .split(RegExp(r'[\n,]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final id = (category['_id'] ?? category['id'] ?? '').toString();
    if (id.isEmpty) return;
    if ((category['defaultKey'] ?? '').toString().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default category permanent hai, disable nahi hogi.'),
        ),
      );
      return;
    }
    final name = (category['name'] ?? 'Category').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disable category?'),
        content: Text('$name app listings se hide ho jayegi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Disable')),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.api.delete('/admin/categories/$id');
    if (_editingCategory != null &&
        ((_editingCategory!['_id'] ?? _editingCategory!['id'] ?? '')
                .toString() ==
            id)) {
      _clearForm();
    }
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          return AppBackground(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                AdminPageTitle(
                  title: 'Category Management',
                  subtitle:
                      'Create service categories with images for app listings.',
                  trailing: FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_busy
                        ? 'Saving...'
                        : _editingCategory == null
                            ? 'Save Category'
                            : 'Update Category'),
                  ),
                ),
                const SizedBox(height: 14),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_editingCategory != null) ...[
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Editing category',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.ink),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => setState(_clearForm),
                              icon: const Icon(Icons.close),
                              label: const Text('Cancel'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextField(
                          controller: _name,
                          decoration: const InputDecoration(
                              labelText: 'Category name')),
                      const SizedBox(height: 10),
                       TextField(
                           controller: _description,
                           decoration:
                               const InputDecoration(labelText: 'Description')),
                       const SizedBox(height: 10),
                       TextField(
                         controller: _services,
                         minLines: 3,
                         maxLines: 6,
                         decoration: const InputDecoration(
                           labelText: 'Services in this category',
                           hintText:
                               'Example: Plumber, Electrician, AC Repair',
                           helperText:
                               'Comma ya new line se multiple services add karo.',
                         ),
                       ),
                       const SizedBox(height: 10),
                       ImageUploadField(
                        label: 'Category image',
                        image: _image,
                        helperText: _editingCategory == null
                            ? 'Shown in admin list and available to app APIs.'
                            : 'Choose a new image only if you want to replace the current one.',
                        onChanged: (image) => setState(() => _image = image),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AdminListHeader(
                    title: 'Current Categories (${categories.length})'),
                const SizedBox(height: 10),
                for (final category in categories)
                  PremiumCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _CategoryThumb(
                        imageUrl:
                            (category['imageUrl'] ?? category['iconUrl'] ?? '')
                                .toString(),
                      ),
                      title: Text((category['name'] ?? 'Category').toString()),
                      subtitle: Text([
                        (category['description'] ?? 'No description').toString(),
                        '${(category['serviceTypes'] as List? ?? []).length} services',
                      ].join(' | ')),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          if ((category['defaultKey'] ?? '').toString().isNotEmpty)
                            const Chip(label: Text('Default')),
                          Chip(
                              label: Text(category['isActive'] == false
                                  ? 'Off'
                                  : 'Live')),
                          IconButton(
                            tooltip: 'Edit category',
                            onPressed: () => _startEdit(category),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Disable category',
                            onPressed:
                                (category['defaultKey'] ?? '').toString().isEmpty
                                    ? () => _deleteCategory(category)
                                    : null,
                            icon: const Icon(Icons.delete_outline),
                            color: AppTheme.crimson,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (categories.isEmpty)
                  const EmptyState(text: 'No live categories found.'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BookingManagementPage extends StatelessWidget {
  const BookingManagementPage({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return _AdminLiveListPage(
      title: 'Booking Management',
      api: api,
      path: '/admin/requests',
      listKey: 'requests',
      icon: Icons.assignment_outlined,
      itemTitle: (item) => (item['title'] ?? 'Service Request').toString(),
      itemSubtitle: (item) =>
          '${item['category'] ?? ''} | ${item['city'] ?? ''} | ${item['status'] ?? ''}',
      actions: const ['assigned', 'in_progress', 'completed', 'cancelled'],
      actionPath: (id) => '/admin/requests/$id/status',
      actionBody: (status) => {'status': status},
    );
  }
}

class ComplaintManagementPage extends StatelessWidget {
  const ComplaintManagementPage({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return _AdminLiveListPage(
      title: 'Complaint Management',
      api: api,
      path: '/admin/reports',
      listKey: 'reports',
      icon: Icons.report_problem_outlined,
      itemTitle: (item) => (item['reason'] ?? 'Complaint').toString(),
      itemSubtitle: (item) =>
          '${item['status'] ?? 'open'} | ${(item['details'] ?? '').toString()}',
      actions: const ['reviewing', 'resolved', 'dismissed'],
      actionPath: (id) => '/admin/reports/$id',
      actionBody: (status) =>
          {'status': status, 'adminNote': 'Updated from mobile admin'},
    );
  }
}

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminPlaceholderPage(
      title: 'Announcements',
      subtitle:
          'Create notices, festival greetings, emergency alerts and push campaigns.',
      icon: Icons.campaign_outlined,
      chips: ['Festival', 'Emergency', 'Offer', 'Community'],
    );
  }
}

class ReportsAnalyticsPage extends StatelessWidget {
  const ReportsAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            CompactHero(
                title: 'Reports & Analytics',
                subtitle: 'Bookings, provider performance and customer growth.',
                icon: Icons.analytics_outlined),
            SizedBox(height: 14),
            StatsGrid(stats: <String, Object>{
              'Bookings': 128,
              'Providers': 42,
              'Growth': '18%',
              'Complaints': 3
            }),
            SizedBox(height: 14),
            _ProgressCard(
                title: 'Popular Services',
                value: .74,
                label: 'Electrician, Plumber, Pandit Ji'),
            _ProgressCard(
                title: 'Area-wise Demand',
                value: .58,
                label: 'Bhilwara central demand is highest'),
            _ProgressCard(
                title: 'Provider Performance',
                value: .82,
                label: 'Most providers responding on time'),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _push = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Language'),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
              ],
              onChanged: (value) =>
                  setState(() => _language = value ?? 'English'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _push,
              onChanged: (value) => setState(() => _push = value),
              title: const Text('Push notifications'),
              subtitle: const Text(
                  'UI ready. Needs Firebase/APNs/FCM setup to send real push.'),
            ),
            SwitchListTile(
              value: AppTheme.themeModeNotifier.value == ThemeMode.dark,
              onChanged: (value) {
                AppTheme.setDarkMode(value);
                setState(() {});
              },
              title: const Text('Dark theme'),
              subtitle: const Text('Apply dark theme across the app.'),
            ),
            const InfoStrip(
                icon: Icons.privacy_tip_outlined,
                text:
                    'Privacy, Terms, Support, and notification settings are represented here.'),
          ],
        ),
      ),
    );
  }
}

class _AdminLiveListPage extends StatefulWidget {
  const _AdminLiveListPage({
    required this.title,
    required this.api,
    required this.path,
    required this.listKey,
    required this.icon,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.actions,
    required this.actionPath,
    required this.actionBody,
  });

  final String title;
  final ApiClient api;
  final String path;
  final String listKey;
  final IconData icon;
  final String Function(Map<String, dynamic>) itemTitle;
  final String Function(Map<String, dynamic>) itemSubtitle;
  final List<String> actions;
  final String Function(String id) actionPath;
  final Map<String, dynamic> Function(String status) actionBody;

  @override
  State<_AdminLiveListPage> createState() => _AdminLiveListPageState();
}

class _AdminLiveListPageState extends State<_AdminLiveListPage> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final data = await widget.api.get(widget.path);
    return (data[widget.listKey] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _update(String id, String action) async {
    setState(() => _busyId = '$id:$action');
    try {
      await widget.api.patch(widget.actionPath(id), widget.actionBody(action));
      setState(() => _future = _load());
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          return AppBackground(
            child: RefreshIndicator(
              onRefresh: () async => setState(() => _future = _load()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                children: [
                  AdminPageTitle(
                    title: widget.title,
                    subtitle: 'Live backend data and quick status actions.',
                  ),
                  const SizedBox(height: 14),
                  AdminMetricGrid(
                    metrics: [
                      AdminMetric(
                        label: 'Total',
                        value: '${items.length}',
                        icon: widget.icon,
                        color: AppTheme.saffron,
                        note: 'Live records',
                      ),
                      AdminMetric(
                        label: 'Actions',
                        value: '${widget.actions.length}',
                        icon: Icons.tune_outlined,
                        color: Colors.blue,
                        note: 'Available updates',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AdminListHeader(title: '${widget.title} (${items.length})'),
                  const SizedBox(height: 10),
                  for (final item in items)
                    PremiumCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(widget.icon, color: AppTheme.saffron),
                            title: Text(widget.itemTitle(item),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            subtitle: Text(widget.itemSubtitle(item),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final action in widget.actions)
                                OutlinedButton(
                                  onPressed: _busyId == '${item['_id']}:$action'
                                      ? null
                                      : () => _update(
                                          (item['_id'] ?? item['id'])
                                              .toString(),
                                          action),
                                  child: Text(action.replaceAll('_', ' ')),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (items.isEmpty)
                    EmptyState(text: '${widget.title} list empty hai.'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminPlaceholderPage extends StatelessWidget {
  const _AdminPlaceholderPage(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.chips});

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CompactHero(title: title, subtitle: subtitle, icon: icon),
            const SizedBox(height: 14),
            PremiumCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final chip in chips) Chip(label: Text(chip))],
              ),
            ),
            const SizedBox(height: 14),
            const InfoStrip(
                icon: Icons.api_outlined,
                text:
                    'This screen has complete UI scaffolding. Full live data actions need matching backend endpoints.'),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard(
      {required this.title, required this.value, required this.label});

  final String title;
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: value, color: AppTheme.saffron),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.muted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CategoryThumb extends StatelessWidget {
  const _CategoryThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.mediaUrl(imageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 44,
        height: 44,
        child: resolved.isEmpty
            ? const ColoredBox(
                color: Color(0xFFFFF0E7),
                child: Icon(Icons.category_outlined, color: AppTheme.saffron),
              )
            : AppRemoteImage(
                url: resolved,
                fit: BoxFit.cover,
                errorBuilder: (_) => const ColoredBox(
                  color: Color(0xFFFFF0E7),
                  child: Icon(Icons.category_outlined, color: AppTheme.saffron),
                ),
              ),
      ),
    );
  }
}

class _AdminTool {
  const _AdminTool(this.title, this.subtitle, this.icon, this.screen);
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;
}
