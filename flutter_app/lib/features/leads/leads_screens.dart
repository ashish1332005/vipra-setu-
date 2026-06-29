import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../shared/app_widgets.dart';
import '../taker/taker_screens.dart';

class ProviderLeads extends StatelessWidget {
  const ProviderLeads({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return LeadsOverview(
      title: 'Incoming contact leads',
      contactLogsPath: '/providers/me/contact-logs',
      api: api,
      footer: RequestsList(api: api, provider: true),
    );
  }
}

class AdminLeads extends StatelessWidget {
  const AdminLeads({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return LeadsOverview(
      title: 'Community contact tracking',
      contactLogsPath: '/admin/contact-logs',
      api: api,
      footer: RequestsList(api: api, admin: true),
      admin: true,
    );
  }
}

class LeadsOverview extends StatefulWidget {
  const LeadsOverview({
    super.key,
    required this.api,
    required this.title,
    required this.contactLogsPath,
    required this.footer,
    this.admin = false,
  });

  final ApiClient api;
  final String title;
  final String contactLogsPath;
  final Widget footer;
  final bool admin;

  @override
  State<LeadsOverview> createState() => _LeadsOverviewState();
}

class _LeadsOverviewState extends State<LeadsOverview> {
  late Future<List<ContactLogItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ContactLogItem>> _load() async {
    final data = await widget.api.get(widget.contactLogsPath);
    return (data['contactLogs'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ContactLogItem.fromJson)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _load()),
      child: FutureBuilder<List<ContactLogItem>>(
        future: _future,
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle(widget.title),
              for (final log in logs)
                Card(
                  child: ListTile(
                    leading: Icon(log.method == 'whatsapp'
                        ? Icons.chat_outlined
                        : Icons.call),
                    title: Text(widget.admin
                        ? '${log.serviceTakerName} -> ${log.providerName}'
                        : log.serviceTakerName),
                    subtitle: Text(
                        '${log.category} | ${log.city} | ${log.rateLabel}'),
                    trailing: Chip(label: Text(log.method)),
                  ),
                ),
              if (logs.isEmpty)
                const EmptyState(text: 'Contact leads abhi empty hain.'),
              const SizedBox(height: 12),
              const SectionTitle('Service requests'),
              SizedBox(height: 520, child: widget.footer),
            ],
          );
        },
      ),
    );
  }
}
