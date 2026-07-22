import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../shared/app_widgets.dart';

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({
    super.key,
    required this.api,
    required this.user,
    required this.onSaved,
  });

  final ApiClient api;
  final AppUser user;
  final ValueChanged<AppUser> onSaved;

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone);
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final data = await widget.api.patch('/auth/me', {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
      });
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      widget.onSaved(user);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      setState(() => _message = error.toString());
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          PremiumCard(
            child: Row(
              children: [
                const CommunityMark(size: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit profile',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink),
                      ),
                      Text(
                        widget.user.role.replaceAll('_', ' '),
                        style: const TextStyle(
                            color: AppTheme.muted, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixIcon: Icon(Icons.phone_outlined)),
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(_message!,
                style: const TextStyle(
                    color: AppTheme.crimson, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_busy ? 'Saving...' : 'Save profile'),
          ),
        ],
      ),
    );
  }
}
