import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/app_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101318) : const Color(0xFFFFFBF7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.saffron.withValues(alpha: .18),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const CommunityMark(size: 92, light: true),
              ),
              const SizedBox(height: 22),
              Text(
                'Vipra Sewa Setu',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'सेवा  •  सहयोग  •  संस्कार',
                style: TextStyle(
                  color: AppTheme.saffron,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Color(0xFFFFE0C5),
                    color: AppTheme.saffron,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'आपका स्वागत है…',
                style: TextStyle(
                  color: isDark ? const Color(0xFFC8CED8) : AppTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
