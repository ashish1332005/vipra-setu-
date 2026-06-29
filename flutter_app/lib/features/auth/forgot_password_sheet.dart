import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../shared/app_widgets.dart';

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key, required this.api});

  final ApiClient api;

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _phone = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;
  String? _devToken;

  Future<void> _requestToken() async {
    setState(() {
      _busy = true;
      _message = null;
      _devToken = null;
    });
    try {
      final data = await widget.api.post('/auth/forgot-password', {
        'phone': _phone.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _message = (data['message'] ?? 'Reset token sent.').toString();
        _devToken = data['resetToken']?.toString();
        if (_devToken != null) _token.text = _devToken!;
      });
    } catch (error) {
      if (mounted) setState(() => _message = _friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final data = await widget.api.post('/auth/reset-password', {
        'phone': _phone.text.trim(),
        'token': _token.text.trim(),
        'newPassword': _password.text,
      });
      if (!mounted) return;
      setState(() => _message =
          (data['message'] ?? 'Password reset successfully.').toString());
    } catch (error) {
      if (mounted) setState(() => _message = _friendlyMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _token.dispose();
    _password.dispose();
    super.dispose();
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
          const SectionTitle(
            'Forgot password',
            subtitle: 'Request a reset token and set a new password.',
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy ? null : _requestToken,
            icon: const Icon(Icons.sms_outlined),
            label: Text(_busy ? 'Please wait...' : 'Request reset token'),
          ),
          if (_devToken != null) ...[
            const SizedBox(height: 10),
            InfoStrip(
              icon: Icons.key_outlined,
              text: 'Dev reset token: $_devToken',
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _token,
            decoration: const InputDecoration(
              labelText: 'Reset token',
              prefixIcon: Icon(Icons.password_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New password',
              prefixIcon: Icon(Icons.lock_reset),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _busy ? null : _resetPassword,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Reset password'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
