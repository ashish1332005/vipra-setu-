import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../shared/app_widgets.dart';
import 'forgot_password_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.role,
    required this.onBackToRoles,
    required this.onLogin,
  });

  final ApiClient api;
  final String role;
  final VoidCallback onBackToRoles;
  final Future<void> Function(AppUser user, String token) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = _register
          ? await widget.api.post('/auth/register', {
              'name': _name.text.trim(),
              'phone': _phone.text.trim(),
              'password': _password.text,
              'role': 'service_taker',
            })
          : await widget.api.post('/auth/login', {
              'phone': _phone.text.trim(),
              'password': _password.text,
            });
      await widget.onLogin(
        AppUser.fromJson(data['user'] as Map<String, dynamic>),
        data['token'].toString(),
      );
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyLoginError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  String _friendlyLoginError(Object error) {
    final message = error.toString();
    if (message.contains('ECONNREFUSED') ||
        message.contains('127.0.0.1:27017') ||
        message.contains('Database connection') ||
        message.contains('Mongo')) {
      return 'Backend database connect nahi ho raha. MONGO_URI set karke server restart karein.';
    }
    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup')) {
      return 'Server connect nahi ho raha. Backend URL/server status check karein.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onBackToRoles();
      },
      child: Scaffold(
        backgroundColor: AppTheme.canvas,
        body: Stack(
          children: [
            const _AuthHero(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 6),
                child: IconButton.filledTonal(
                  onPressed: widget.onBackToRoles,
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 248, 18, 24),
                children: [
                  _AuthPanel(
                    api: widget.api,
                    register: _register,
                    busy: _busy,
                    error: _error,
                    name: _name,
                    phone: _phone,
                    password: _password,
                    role: widget.role,
                    onModeChanged: (value) => setState(() {
                      _register = value;
                      _error = null;
                    }),
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 14),
                  const _ProviderNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AppAssets.heroWorkers,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.deepRed.withValues(alpha: .18),
                  AppTheme.deepRed.withValues(alpha: .72),
                  AppTheme.canvas,
                ],
                stops: const [.08, .68, 1],
              ),
            ),
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CommunityMark(size: 52, light: true),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vipra Sewa Setu',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Dharma | Seva | Samaj',
                              style: TextStyle(
                                  color: Color(0xFFFFE4E6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    'Trusted local services for the community',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.06),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Book verified providers, manage requests, and stay connected with one simple app.',
                    style: TextStyle(
                        color: Color(0xFFFFE4E6),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 62),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.api,
    required this.register,
    required this.busy,
    required this.error,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    required this.onModeChanged,
    required this.onSubmit,
  });

  final ApiClient api;
  final bool register;
  final bool busy;
  final String? error;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController password;
  final String role;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .8)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepRed.withValues(alpha: .15),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (role == 'service_taker') ...[
            _ModeSwitch(register: register, onChanged: onModeChanged),
            const SizedBox(height: 18),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                role == 'admin' ? 'Admin Login' : 'Provider Login',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.navy, fontWeight: FontWeight.w800),
              ),
            ),
          Text(
            register ? 'Create account' : 'Welcome back',
            style: const TextStyle(
                fontSize: 25, fontWeight: FontWeight.w800, color: AppTheme.ink),
          ),
          const SizedBox(height: 5),
          Text(
            role == 'service_provider'
                ? 'Provider account is created by admin. Use assigned mobile and password.'
                : role == 'admin'
                    ? 'Admin workspace login for platform control.'
                    : register
                        ? 'Start booking trusted local services.'
                        : 'Login to continue your seva dashboard.',
            style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
                height: 1.4),
          ),
          const SizedBox(height: 20),
          if (register && role == 'service_taker') ...[
            TextField(
              controller: name,
              decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14)),
              child: Text(error!,
                  style: const TextStyle(
                      color: AppTheme.crimson, fontWeight: FontWeight.w800)),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            child: Text(busy
                ? 'Please wait...'
                : (register ? 'Create account' : 'Login')),
          ),
          const SizedBox(height: 14),
          if (!register)
            TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => ForgotPasswordSheet(api: api),
              ),
              child: const Text('Forgot password?'),
            ),
          if (role != 'service_taker')
            const Text(
              'Signup is available only for customers. Provider/Admin accounts are controlled by admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                  child: _TrustPill(
                      icon: Icons.verified_user_outlined, text: 'Verified')),
              SizedBox(width: 8),
              Expanded(
                  child: _TrustPill(
                      icon: Icons.location_on_outlined, text: 'Local')),
              SizedBox(width: 8),
              Expanded(
                  child:
                      _TrustPill(icon: Icons.handshake_outlined, text: 'Seva')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.register, required this.onChanged});

  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF3EE),
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
              child: _ModeButton(
                  text: 'Login',
                  selected: !register,
                  onTap: () => onChanged(false))),
          Expanded(
              child: _ModeButton(
                  text: 'Sign up',
                  selected: register,
                  onTap: () => onChanged(true))),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton(
      {required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.deepRed : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.deepRed.withValues(alpha: .18),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: selected ? Colors.white : AppTheme.muted,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF8F3),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.deepRed, size: 19),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ProviderNote extends StatelessWidget {
  const _ProviderNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: const Row(
        children: [
          Icon(Icons.admin_panel_settings_outlined, color: AppTheme.deepRed),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Provider accounts admin banayega. Provider wahi mobile/password se login karega.',
              style: TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                  height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
