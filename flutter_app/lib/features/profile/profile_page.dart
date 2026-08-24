import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../shared/app_widgets.dart';
import '../admin/admin_management.dart';
import '../auth/change_password_sheet.dart';
import '../taker/taker_screens.dart';
import 'profile_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.api,
    required this.user,
    required this.onUserChanged,
    required this.onLogout,
  });

  final ApiClient api;
  final AppUser user;
  final ValueChanged<AppUser> onUserChanged;
  final VoidCallback onLogout;

  Future<Map<String, Object>> _loadStats() async {
    try {
      if (user.role == 'admin') {
        final data = await api.get('/admin/dashboard');
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        return {
          'primaryValue': stats['openRequests'] ?? 0,
          'primaryLabel': 'Requests',
          'secondaryValue': stats['totalProviders'] ?? 0,
          'secondaryLabel': 'Providers',
        };
      }
      if (user.role == 'service_provider') {
        final data = await api.get('/providers/me/analytics');
        final stats = data['analytics'] as Map<String, dynamic>? ?? {};
        return {
          'primaryValue': stats['totalLeads'] ?? 0,
          'primaryLabel': 'Leads',
          'secondaryValue': stats['rating'] ?? 0,
          'secondaryLabel': 'Rating',
        };
      }
      final data = await api.get('/service-takers/me/requests');
      final requests = data['requests'] as List? ?? [];
      final completed = requests
          .whereType<Map<String, dynamic>>()
          .where((item) => item['status'] == 'completed')
          .length;
      return {
        'primaryValue': requests.length,
        'primaryLabel': 'Bookings',
        'secondaryValue': completed,
        'secondaryLabel': 'Completed',
      };
    } catch (_) {
      return {
        'primaryValue': 0,
        'primaryLabel': user.role == 'admin'
            ? 'Requests'
            : user.role == 'service_provider'
                ? 'Leads'
                : 'Bookings',
        'secondaryValue': 0,
        'secondaryLabel': user.role == 'admin'
            ? 'Providers'
            : user.role == 'service_provider'
                ? 'Rating'
                : 'Completed',
      };
    }
  }

  String get _roleLabel {
    return switch (user.role) {
      'admin' => 'Platform Admin',
      'service_provider' => 'Service Provider',
      _ => 'Service Taker',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.paddingOf(context).bottom + 120,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.navy, Color(0xFF263858), AppTheme.saffron],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.navy.withValues(alpha: .18),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(AppAssets.providerElectrician,
                          width: 78, height: 78, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(user.phone,
                              style: const TextStyle(
                                  color: Color(0xFFFFEAD8),
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          MiniBadge(
                              icon: Icons.workspace_premium_outlined,
                              text: _roleLabel),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, Object>>(
                  future: _loadStats(),
                  builder: (context, snapshot) {
                    final stats = snapshot.data ??
                        {
                          'primaryValue': '...',
                          'primaryLabel': 'Loading',
                          'secondaryValue': '...',
                          'secondaryLabel': 'Stats',
                        };
                    return Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(
                            value: stats['primaryValue'].toString(),
                            label: stats['primaryLabel'].toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileStat(
                            value: stats['secondaryValue'].toString(),
                            label: stats['secondaryLabel'].toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => ProfileSheet(
                                  api: api, user: user, onSaved: onUserChanged),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: const Text('Edit'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProfileOption(
              icon: Icons.assignment_outlined,
              title: user.role == 'admin'
                  ? 'All requests'
                  : user.role == 'service_provider'
                      ? 'Assigned jobs'
                      : 'My bookings',
              subtitle: user.role == 'admin'
                  ? 'Review platform bookings'
                  : user.role == 'service_provider'
                      ? 'Track assigned service work'
                      : 'Track requests and history',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RequestsList(
                      api: api,
                      admin: user.role == 'admin',
                      provider: user.role == 'service_provider',
                    ),
                  ))),
          _ProfileOption(
              icon: Icons.support_agent_outlined,
              title: 'Support',
              subtitle: 'Help, complaints and contact',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SupportPage(api: api, user: user),
                  ))),
          _ProfileOption(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How your data is handled',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const InfoContentPage(
                      title: 'Privacy Policy',
                      icon: Icons.privacy_tip_outlined,
                      paragraphs: [
                        'Vipra Sewa Setu stores your profile, mobile number, service requests and contact activity only to provide local service features.',
                        'Provider contact logs help admins improve trust and platform safety.',
                        'Do not share sensitive payment or identity details outside verified service workflows.',
                      ],
                    ),
                  ))),
          _ProfileOption(
              icon: Icons.info_outline,
              title: 'About Vipra Sewa Setu',
              subtitle: 'Community service platform',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AboutVipraSetuPage(),
                  ))),
          _ProfileOption(
              icon: Icons.lock_reset,
              title: 'Change password',
              subtitle: 'Update your account password',
              onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ChangePasswordSheet(api: api),
                  )),
          _ProfileOption(
              icon: Icons.settings_outlined,
              title: 'Language & Settings',
              subtitle: 'Hindi/English, theme and notifications',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()))),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class SupportPage extends StatefulWidget {
  const SupportPage({super.key, required this.api, required this.user});

  final ApiClient api;
  final AppUser user;

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _reason = TextEditingController(text: 'Need help');
  final _details = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (widget.user.role != 'service_taker') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Provider/Admin support is handled by admin team.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.api.post('/service-takers/me/reports', {
        'reason': _reason.text.trim().isEmpty
            ? 'Support request'
            : _reason.text.trim(),
        'details': _details.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support request submitted.')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CompactHero(
              title: 'How can we help?',
              subtitle:
                  'Complaint, help request ya contact issue submit karein.',
              icon: Icons.support_agent_outlined,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _details,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Details'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.send_outlined),
              label: Text(_busy ? 'Submitting...' : 'Submit Support Request'),
            ),
            const SizedBox(height: 14),
            const InfoStrip(
              icon: Icons.call_outlined,
              text:
                  'Urgent issue ke liye admin/provider ko direct call ya WhatsApp bhi kar sakte hain.',
            ),
          ],
        ),
      ),
    );
  }
}

class AboutVipraSetuPage extends StatelessWidget {
  const AboutVipraSetuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.navy, Color(0xFF334A70)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.navy.withValues(alpha: .18),
                      blurRadius: 24,
                      offset: const Offset(0, 14))
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                      right: -58,
                      top: -75,
                      child: Image.asset(AppAssets.saffronDhwaj,
                          width: 235,
                          height: 300,
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(.28))),
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommunityMark(size: 70, light: true),
                        SizedBox(height: 22),
                        Text('Vipra Sewa Setu',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900)),
                        SizedBox(height: 6),
                        Text(
                            'A unified platform for social service, employment and community growth.',
                            style: TextStyle(
                                color: Color(0xFFFFE5D4),
                                fontSize: 15,
                                height: 1.45,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 18),
                        _AboutBadge(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _AboutHeading('Our purpose',
                'Technology that brings people, opportunities and dependable local support closer together.'),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(
                    child: _AboutPillar(
                        icon: Icons.diversity_3_outlined,
                        title: 'Sangathan',
                        subtitle: 'Connect the community')),
                SizedBox(width: 10),
                Expanded(
                    child: _AboutPillar(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'Seva',
                        subtitle: 'Serve with dignity')),
                SizedBox(width: 10),
                Expanded(
                    child: _AboutPillar(
                        icon: Icons.handshake_outlined,
                        title: 'Sahyog',
                        subtitle: 'Grow together')),
              ],
            ),
            const SizedBox(height: 22),
            const _AboutHeading('One platform. Everyone connected.',
                'Customers can discover services, providers can build livelihoods, and admins can keep every interaction safer and more transparent.'),
            const SizedBox(height: 14),
            const _AboutRole(
                icon: Icons.search_rounded,
                title: 'For community members',
                text:
                    'Find trusted professionals, request help and track services in one place.'),
            const _AboutRole(
                icon: Icons.engineering_outlined,
                title: 'For service providers',
                text:
                    'Reach genuine local opportunities and grow through meaningful work.'),
            const _AboutRole(
                icon: Icons.verified_user_outlined,
                title: 'Built around trust',
                text:
                    'Clear workflows, accountable support and community-first service discovery.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E4),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFD4B8))),
              child: const Row(
                children: [
                  CircleAvatar(
                      backgroundColor: AppTheme.saffron,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.format_quote_rounded)),
                  SizedBox(width: 14),
                  Expanded(
                      child: Text(
                          'Connected community. Trusted service. Shared progress.',
                          style: TextStyle(
                              color: AppTheme.navy,
                              height: 1.35,
                              fontSize: 16,
                              fontWeight: FontWeight.w900))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutBadge extends StatelessWidget {
  const _AboutBadge();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: .2))),
      child: const Text('SEVA  •  SAHYOG  •  SANSKAR',
          style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              letterSpacing: .8,
              fontWeight: FontWeight.w900)));
}

class _AboutHeading extends StatelessWidget {
  const _AboutHeading(this.title, this.text);
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(text,
            style: const TextStyle(
                color: AppTheme.softText,
                height: 1.5,
                fontWeight: FontWeight.w600))
      ]);
}

class _AboutPillar extends StatelessWidget {
  const _AboutPillar(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.line),
          boxShadow: [
            BoxShadow(
                color: AppTheme.navy.withValues(alpha: .06),
                blurRadius: 14,
                offset: const Offset(0, 7))
          ]),
      child: Column(children: [
        CircleAvatar(
            backgroundColor: const Color(0xFFFFE9D8),
            foregroundColor: AppTheme.saffron,
            child: Icon(icon)),
        const SizedBox(height: 10),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.navy, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 10,
                height: 1.25,
                fontWeight: FontWeight.w600))
      ]));
}

class _AboutRole extends StatelessWidget {
  const _AboutRole(
      {required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.line)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0E6),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppTheme.saffron)),
        const SizedBox(width: 13),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(text,
              style: const TextStyle(
                  color: AppTheme.muted,
                  height: 1.4,
                  fontSize: 13,
                  fontWeight: FontWeight.w600))
        ]))
      ]));
}

class InfoContentPage extends StatelessWidget {
  const InfoContentPage({
    super.key,
    required this.title,
    required this.icon,
    required this.paragraphs,
  });

  final String title;
  final IconData icon;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CompactHero(title: title, subtitle: 'Vipra Sewa Setu', icon: icon),
            const SizedBox(height: 14),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final paragraph in paragraphs) ...[
                    Text(paragraph,
                        style:
                            const TextStyle(height: 1.45, color: AppTheme.ink)),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFFFEAD8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.saffron),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      ),
    );
  }
}
