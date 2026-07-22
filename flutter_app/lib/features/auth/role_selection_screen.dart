import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/app_widgets.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const BrandHeader(),
              const SizedBox(height: 24),
              const Text('Continue as',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink)),
              const SizedBox(height: 8),
              const Text('Choose your app workspace.',
                  style: TextStyle(
                      color: AppTheme.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 22),
              _RoleCard(
                icon: Icons.home_repair_service_outlined,
                title: 'Customer',
                subtitle: 'I need a service',
                onTap: () => onSelected('service_taker'),
              ),
              _RoleCard(
                icon: Icons.engineering_outlined,
                title: 'Service Provider',
                subtitle: 'Provider login, account created by admin',
                onTap: () => onSelected('service_provider'),
              ),
              _RoleCard(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin',
                subtitle: 'Manage providers, bookings and reports',
                onTap: () => onSelected('admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard(
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
            backgroundColor: const Color(0xFFFFF0E8),
            foregroundColor: AppTheme.saffron,
            child: Icon(icon)),
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
