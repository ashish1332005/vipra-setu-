import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../shared/app_widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<_AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_AppNotification>> _load() async {
    final data = await widget.api.get('/notifications');
    return (data['notifications'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_AppNotification.fromJson)
        .toList();
  }

  Future<void> _markRead(_AppNotification item) async {
    if (item.read) return;
    await widget.api.patch('/notifications/${item.id}/read', {});
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.canvas,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: FutureBuilder<List<_AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  EmptyState(
                    text: snapshot.error.toString(),
                    icon: Icons.notifications_off_outlined,
                  ),
                ],
              );
            }
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  EmptyState(
                    text: 'Abhi koi notification nahi hai.',
                    icon: Icons.notifications_none,
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return PremiumCard(
                  padding: const EdgeInsets.all(14),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: item.read
                          ? AppTheme.line
                          : AppTheme.saffron.withValues(alpha: .12),
                      child: Icon(
                        item.read
                            ? Icons.notifications_none
                            : Icons.notifications_active_outlined,
                        color: item.read ? AppTheme.muted : AppTheme.saffron,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(item.message),
                    ),
                    trailing: item.read
                        ? null
                        : const Icon(Icons.mark_email_read_outlined),
                    onTap: () => _markRead(item),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AppNotification {
  const _AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
  });

  final String id;
  final String title;
  final String message;
  final bool read;

  factory _AppNotification.fromJson(Map<String, dynamic> json) {
    return _AppNotification(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      read: (json['readAt']?.toString() ?? '').isNotEmpty,
    );
  }
}
