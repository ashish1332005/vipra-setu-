import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/models.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/role_selection_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/shell/role_shell.dart';
import 'app_theme.dart';

class VipraSetuApp extends StatefulWidget {
  const VipraSetuApp({super.key, required this.api});

  final ApiClient api;

  @override
  State<VipraSetuApp> createState() => _VipraSetuAppState();
}

class _VipraSetuAppState extends State<VipraSetuApp> {
  static const _onboardingDoneKey = 'onboardingDone';
  static const _onboardingVersionKey = 'onboardingVersion';
  static const _currentOnboardingVersion = 3;
  static const _selectedRoleKey = 'selectedRole';

  AppUser? _user;
  bool _loading = true;
  bool _onboardingDone = false;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final splashTimer = Stopwatch()..start();
    final prefs = await SharedPreferences.getInstance();
    _onboardingDone =
        prefs.getInt(_onboardingVersionKey) == _currentOnboardingVersion;
    _selectedRole = prefs.getString(_selectedRoleKey);
    await AppTheme.loadThemeMode();
    await widget.api.loadToken();
    try {
      final data = await widget.api.get('/auth/me');
      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      await widget.api.clearToken();
    }
    const minimumSplashTime = Duration(milliseconds: 900);
    final remaining = minimumSplashTime - splashTimer.elapsed;
    if (!remaining.isNegative) await Future<void>.delayed(remaining);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onLogin(AppUser user, String token) async {
    await widget.api.saveToken(token);
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    await widget.api.clearToken();
    setState(() => _user = null);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
    await prefs.setInt(_onboardingVersionKey, _currentOnboardingVersion);
    setState(() => _onboardingDone = true);
  }

  Future<void> _selectRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedRoleKey, role);
    setState(() => _selectedRole = role);
  }

  Future<void> _backToRoles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedRoleKey);
    setState(() => _selectedRole = null);
  }

  void _updateUser(AppUser user) {
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vipra Sewa Setu',
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return ColoredBox(
            color: isDark ? const Color(0xFF101318) : AppTheme.canvas,
            child: SafeArea(
              top: true,
              bottom: false,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: _loading
            ? const SplashScreen()
            : _user == null
                ? !_onboardingDone
                    ? OnboardingScreen(onDone: _completeOnboarding)
                    : _selectedRole == null
                        ? RoleSelectionScreen(onSelected: _selectRole)
                        : LoginScreen(
                            api: widget.api,
                            role: _selectedRole!,
                            onBackToRoles: _backToRoles,
                            onLogin: _onLogin,
                          )
                : RoleShell(
                    api: widget.api,
                    user: _user!,
                    onUserChanged: _updateUser,
                    onLogout: _logout,
                  ),
      ),
    );
  }
}
