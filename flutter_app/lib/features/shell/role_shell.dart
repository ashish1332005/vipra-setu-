import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../shared/app_widgets.dart';
import '../admin/admin_management.dart';
import '../admin/admin_screens.dart';
import '../booking/booking_screens.dart';
import '../leads/leads_screens.dart';
import '../notifications/notifications_page.dart';
import '../providers/provider_screens.dart';
import '../profile/profile_page.dart';
import '../profile/profile_sheet.dart';
import '../taker/taker_screens.dart';

class RoleShell extends StatefulWidget {
  const RoleShell(
      {super.key,
      required this.api,
      required this.user,
      required this.onUserChanged,
      required this.onLogout});

  final ApiClient api;
  final AppUser user;
  final ValueChanged<AppUser> onUserChanged;
  final VoidCallback onLogout;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = switch (widget.user.role) {
      'admin' => [
          NavTab('Dashboard', Icons.space_dashboard_outlined,
              AdminHome(api: widget.api)),
          NavTab('Providers', Icons.verified_user_outlined,
              AdminProviders(api: widget.api)),
          NavTab('Manage', Icons.tune_outlined,
              AdminManagementHub(api: widget.api)),
          NavTab(
              'Leads', Icons.assignment_outlined, AdminLeads(api: widget.api)),
          NavTab(
              'Profile',
              Icons.person_outline,
              ProfilePage(
                  api: widget.api,
                  user: widget.user,
                  onUserChanged: widget.onUserChanged,
                  onLogout: widget.onLogout)),
        ],
      'service_provider' => [
          NavTab('Dashboard', Icons.dashboard_outlined,
              ProviderHome(api: widget.api, user: widget.user)),
          NavTab('Jobs', Icons.work_outline, ProviderLeads(api: widget.api)),
          NavTab('Services', Icons.design_services_outlined,
              ProviderServices(api: widget.api)),
          NavTab(
              'Profile',
              Icons.person_outline,
              ProfilePage(
                  api: widget.api,
                  user: widget.user,
                  onUserChanged: widget.onUserChanged,
                  onLogout: widget.onLogout)),
        ],
      _ => [
          NavTab('Home', Icons.home_outlined,
              TakerHome(api: widget.api, user: widget.user)),
          NavTab('Services', Icons.grid_view_rounded,
              TakerServicesPage(api: widget.api)),
          NavTab('Book Service', Icons.add, BookServicePage(api: widget.api)),
          NavTab('Bookings', Icons.calendar_month_outlined,
              RequestsList(api: widget.api)),
          NavTab(
              'Profile',
              Icons.person_outline,
              ProfilePage(
                  api: widget.api,
                  user: widget.user,
                  onUserChanged: widget.onUserChanged,
                  onLogout: widget.onLogout)),
        ],
    };

    final isTaker = widget.user.role == 'service_taker';
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: isTaker
          ? PreferredSize(
              preferredSize:
                  Size.fromHeight(_index == 0 ? 0 : topPadding + 164),
              child: _TakerShellHeader(
                visible: _index != 0,
                title: tabs[_index].label == 'Bookings'
                    ? 'My Bookings'
                    : tabs[_index].label,
                subtitle: switch (tabs[_index].label) {
                  'Services' => '500+ Verified Professionals at your service',
                  'Bookings' => 'Track and manage all your service bookings',
                  _ => 'Vipra Sewa Setu',
                },
                onSearch: tabs[_index].label == 'Services'
                    ? _openProviderSearch
                    : null,
                onNotifications: _openNotifications,
                onMenuSelected: _handleShellAction,
              ),
            )
          : AppBar(
              titleSpacing: 16,
              title: Row(
                children: [
                  const CommunityMark(size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vipra Sewa Setu'),
                        Text(
                          tabs[_index].label,
                          style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                PopupMenuButton<_ShellAction>(
                  tooltip: 'Account',
                  icon: const Icon(Icons.more_vert),
                  onSelected: _handleShellAction,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _ShellAction.editProfile,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.account_circle_outlined),
                        title: Text('Edit profile'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ShellAction.logout,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: SafeArea(
        top: isTaker ? _index == 0 : false,
        bottom: false,
        child: tabs[_index].screen,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF171B22) : Colors.white)
                .withValues(alpha: .94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: isDark ? const Color(0xFF303744) : AppTheme.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .24 : .12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: _ShellBottomNav(
              tabs: tabs,
              selectedIndex: _index,
              onSelected: (value) => setState(() => _index = value),
            ),
          ),
        ),
      ),
    );
  }

  void _openProviderSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProviderSearch(api: widget.api)),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NotificationsPage(api: widget.api)),
    );
  }

  void _handleShellAction(_ShellAction value) {
    switch (value) {
      case _ShellAction.editProfile:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => ProfileSheet(
            api: widget.api,
            user: widget.user,
            onSaved: widget.onUserChanged,
          ),
        );
      case _ShellAction.logout:
        widget.onLogout();
    }
  }
}

class _ShellBottomNav extends StatelessWidget {
  const _ShellBottomNav({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: _ShellNavItem(
                tab: tabs[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBook = tab.label == 'Book Service';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = selected
        ? AppTheme.saffron
        : isDark
            ? const Color(0xFFE6E1DE)
            : const Color(0xFF55443E);
    final labelColor = selected
        ? (isBook ? AppTheme.saffron : AppTheme.saffron)
        : isDark
            ? const Color(0xFFD2CBC7)
            : const Color(0xFF62534E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected && !isBook ? 14 : 8,
              vertical: isBook ? 4 : 7,
            ),
            decoration: BoxDecoration(
              color: selected && !isBook
                  ? const Color(0xFFFFE9DE)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBook)
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF7A1A), Color(0xFFFF3D18)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.saffron
                              .withValues(alpha: selected ? .38 : .24),
                          blurRadius: selected ? 18 : 12,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  )
                else
                  Icon(tab.icon, color: iconColor, size: 25),
                SizedBox(height: isBook ? 2 : 4),
                Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected && !isBook ? AppTheme.saffron : labelColor,
                    fontSize: isBook ? 11 : 12,
                    height: 1,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ShellAction { editProfile, logout }

class NavTab {
  const NavTab(this.label, this.icon, this.screen);

  final String label;
  final IconData icon;
  final Widget screen;
}

class _TakerShellHeader extends StatelessWidget {
  const _TakerShellHeader({
    required this.visible,
    required this.title,
    required this.subtitle,
    required this.onMenuSelected,
    this.onSearch,
    this.onNotifications,
  });

  final bool visible;
  final String title;
  final String subtitle;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;
  final ValueChanged<_ShellAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final top = MediaQuery.paddingOf(context).top;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: top + 164,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.welcomeHeaderBg,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withValues(alpha: .97),
                      const Color(0xFFFFF3E8).withValues(alpha: .86),
                      Colors.white.withValues(alpha: .46),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, top + 18, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CommunityMark(size: 42),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vipra Sewa Setu',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 20,
                                    height: 1.05,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(height: 3),
                            Text('Trusted local services',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      PopupMenuButton<_ShellAction>(
                        tooltip: 'Account',
                        icon: const Icon(Icons.more_vert),
                        onSelected: onMenuSelected,
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _ShellAction.editProfile,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.account_circle_outlined),
                              title: Text('Edit profile'),
                            ),
                          ),
                          PopupMenuItem(
                            value: _ShellAction.logout,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.logout),
                              title: Text('Logout'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppTheme.ink,
                                    fontSize: 26,
                                    height: 1.08,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      _HeaderActionButton(
                        icon: Icons.notifications_none,
                        badge: '3',
                        onTap: onNotifications,
                      ),
                      if (onSearch != null) ...[
                        const SizedBox(width: 10),
                        _HeaderActionButton(
                            icon: Icons.search, onTap: onSearch),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.icon, this.badge, this.onTap});

  final IconData icon;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: AppTheme.ink, size: 27),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -3,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  color: AppTheme.saffron, shape: BoxShape.circle),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}
