import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../shared/app_widgets.dart';

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key, required this.api});

  final ApiClient api;

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;
  String? _message;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.api.patch('/auth/password', {
        'currentPassword': _current.text,
        'newPassword': _next.text,
      });
      setState(() => _message = 'Password changed successfully');
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
          const SectionTitle('Change password'),
          TextField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password')),
          const SizedBox(height: 10),
          TextField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password')),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(_message!),
          ],
          const SizedBox(height: 14),
          FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Updating...' : 'Update password')),
        ],
      ),
    );
  }
}
