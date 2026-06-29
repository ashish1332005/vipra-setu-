import 'dart:convert';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../core/api_config.dart';
import '../core/models.dart';

class AppAssets {
  static const logo = 'assets/logo.jpeg';
  static const parshuramHero = 'assets/parshuram-hero.png';
  static const vipraSena = 'assets/viprasena.jpeg';
  static const bpf = 'assets/bpf.jpeg';
  static const heroOne = 'assets/hero-slide-1.jpg';
  static const heroTwo = 'assets/hero-slide-2.jpg';
  static const heroThree = 'assets/hero-slide-3.jpg';
  static const adOne = 'assets/Add.png';
  static const adTwo = 'assets/add2.png';
  static const adThree = 'assets/add3.jpeg';
  static const servicePandit = 'assets/services/service-pandit.png';
  static const serviceElectrician = 'assets/services/service-electrician.png';
  static const servicePlumber = 'assets/services/service-plumber.png';
  static const serviceAcRepair = 'assets/services/service-ac-repair.png';
  static const serviceCleaning = 'assets/services/service-cleaning.png';
  static const servicePainter = 'assets/services/service-painter.png';
  static const serviceTutor = 'assets/services/service-tutor.png';
  static const serviceDriver = 'assets/services/service-driver.png';
  static const serviceCook = 'assets/services/service-cook.png';
  static const serviceBeauty = 'assets/services/service-beauty.png';
  static const heroWorkers = 'assets/premium/hero-workers.png';
  static const providerElectrician = 'assets/premium/provider-electrician.png';
  static const providerPlumber = 'assets/premium/provider-plumber.png';
  static const trackLive = 'assets/premium/track-live.png';
  static const homeHeroV2 = 'assets/premium/home-hero-v2.png';
  static const homeServiceBannerV3 =
      'assets/premium/home-service-banner-v3.png';
  static const welcomeHeaderBg = 'assets/premium/welcome-header-bg.png';
  static const onboardingVipraSetu =
      'assets/premium/onboarding-vipra-setu-v2.png';
  static const onboardingBpf = 'assets/premium/onboarding-bpf-v2.png';
  static const onboardingBpfLogo = 'assets/premium/onboarding-bpf-logo.png';
  static const onboardingVipraSenaLogo =
      'assets/premium/onboarding-vipra-sena-logo.png';
  static const onboardingParshuramLogo =
      'assets/premium/onboarding-parshuram-logo.png';
  static const serviceCarpenter = 'assets/services/service-carpenter.png';
  static const servicePhotographer = 'assets/services/service-photographer.png';
  static const serviceComputerRepair =
      'assets/services/service-computer-repair.png';
  static const serviceMobileRepair =
      'assets/services/service-mobile-repair.png';
  static const serviceEventManagement =
      'assets/services/service-event-management.png';
  static const categoryHomeServices =
      'assets/generated/categories/category-home-services.png';
  static const categoryEvents =
      'assets/generated/categories/category-events.png';
  static const categoryEducation =
      'assets/generated/categories/category-education.png';
  static const categoryHospitalCare =
      'assets/generated/categories/category-hospital-care.png';
  static const categoryPropertyRent =
      'assets/generated/categories/category-property-rent.png';
  static const categoryFoodStay =
      'assets/generated/categories/category-food-stay.png';
  static const categoryBeautyWellness =
      'assets/generated/categories/category-beauty-wellness.png';
  static const categoryTransport =
      'assets/generated/categories/category-transport.png';
  static const categoryLegalFinance =
      'assets/generated/categories/category-legal-finance.png';
  static const categoryItDigital =
      'assets/generated/categories/category-it-digital.png';
  static const categoryOtherServices =
      'assets/generated/categories/category-other-services.png';
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.center = false});

  final bool center;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const CommunityMark(size: 86),
        const SizedBox(height: 16),
        const Text(
          'Vipra Sewa Setu',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 31, fontWeight: FontWeight.w700, color: AppTheme.ink),
        ),
        const SizedBox(height: 6),
        Text(
          'Seva, trust aur community ka modern app',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
    return center ? Center(child: content) : content;
  }
}

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF101318),
                    Color(0xFF151922),
                    Color(0xFF101318),
                  ]
                : const [
                    Color(0xFFFFFFFF),
                    Color(0xFFFFF7F1),
                    AppTheme.canvas,
                  ],
          ),
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

class AppRemoteImage extends StatelessWidget {
  const AppRemoteImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final Widget Function(BuildContext context)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.mediaUrl(url);
    if (resolved.isEmpty) return _fallback(context);

    final dataMatch =
        RegExp(r'^data:([^;]+);base64,(.+)$').firstMatch(resolved);
    if (dataMatch != null) {
      final mime = dataMatch.group(1) ?? '';
      final payload = dataMatch.group(2) ?? '';
      if (mime.contains('svg')) return _fallback(context);
      try {
        return Image.memory(
          base64Decode(payload),
          fit: fit,
          alignment: alignment,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _fallback(context),
        );
      } catch (_) {
        return _fallback(context);
      }
    }

    return Image.network(
      resolved,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return errorBuilder?.call(context) ??
        const ColoredBox(color: AppTheme.navy);
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.margin});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .22 : .08),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: isDark ? const Color(0xFF171B22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark ? const Color(0xFF303744) : AppTheme.line),
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class CommunityMark extends StatelessWidget {
  const CommunityMark({super.key, required this.size, this.light = false});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: light ? Colors.white : AppTheme.saffron,
        borderRadius: BorderRadius.circular(size * .24),
        border: Border.all(
          color: light
              ? Colors.white.withValues(alpha: .45)
              : const Color(0xFFFFD5C2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: light ? 0 : .16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .2),
        child: Image.asset(
          AppAssets.logo,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: light ? AppTheme.saffron : Colors.white,
                fontSize: size * .34,
                letterSpacing: 0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CommunityHero extends StatelessWidget {
  const CommunityHero(
      {super.key,
      required this.name,
      this.title = 'Trusted local services, community verified.'});

  final String name;
  final String title;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 380;
    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: Container(
        constraints: const BoxConstraints(minHeight: 156),
        padding: EdgeInsets.all(narrow ? 16 : 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.navy, Color(0xFF263858), AppTheme.saffron],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.navy.withValues(alpha: .18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              top: -24,
              child: Icon(Icons.auto_awesome,
                  size: 96, color: Colors.white.withValues(alpha: .08)),
            ),
            Positioned(
              right: 18,
              bottom: 10,
              child: Icon(Icons.handyman_outlined,
                  size: 72, color: Colors.white.withValues(alpha: .08)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CommunityMark(size: narrow ? 48 : 58, light: true),
                    SizedBox(width: narrow ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Namaste, $name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: narrow ? 18 : 22,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: const Color(0xFFFFE4E6),
                                fontSize: narrow ? 12 : 14,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w700,
                                height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MiniBadge(icon: Icons.verified_outlined, text: 'Verified'),
                    MiniBadge(icon: Icons.location_on_outlined, text: 'Local'),
                    MiniBadge(
                        icon: Icons.dashboard_customize_outlined,
                        text: 'Smart booking'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CompactHero extends StatelessWidget {
  const CompactHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.auto_awesome,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navy, Color(0xFF293B5F), AppTheme.saffron],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: .16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFFFFE4E6),
                      fontWeight: FontWeight.w700,
                      height: 1.32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CulturalImagePanel extends StatelessWidget {
  const CulturalImagePanel({super.key, this.height = 250});

  final double height;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(AppAssets.parshuramHero,
                  fit: BoxFit.cover, alignment: Alignment.topCenter),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.deepRed.withValues(alpha: .78),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  'Dharma, Seva aur Samaj ko jodne wala trusted digital setu',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PartnerStrip extends StatelessWidget {
  const PartnerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
            child: PartnerLogo(asset: AppAssets.logo, label: 'Vipra Setu')),
        SizedBox(width: 8),
        Expanded(
            child:
                PartnerLogo(asset: AppAssets.vipraSena, label: 'Vipra Sena')),
        SizedBox(width: 8),
        Expanded(child: PartnerLogo(asset: AppAssets.bpf, label: 'BPF')),
      ],
    );
  }
}

class PartnerLogo extends StatelessWidget {
  const PartnerLogo({super.key, required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(asset, width: 42, height: 42, fit: BoxFit.cover),
          ),
          const SizedBox(height: 6),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class ImagePromoBanner extends StatelessWidget {
  const ImagePromoBanner({
    super.key,
    this.asset = AppAssets.heroOne,
    this.title = 'Trusted services around your community',
    this.subtitle = 'Book, compare, contact and track with confidence.',
  });

  final String asset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 154,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(asset, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.deepRed.withValues(alpha: .86),
                      AppTheme.deepRed.withValues(alpha: .42),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 210,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.18)),
                        const SizedBox(height: 6),
                        Text(subtitle,
                            style: const TextStyle(
                                color: Color(0xFFFFE4E6),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.35)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LiveAdPreviewCard extends StatelessWidget {
  const LiveAdPreviewCard({super.key, required this.ad, this.onTap});

  final Map<String, dynamic> ad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.mediaUrl((ad['imageUrl'] ?? '').toString());
    final title = (ad['title'] ?? 'Community update').toString();
    final subtitle = (ad['subtitle'] ?? ad['ctaLabel'] ?? '').toString();
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                AppRemoteImage(
                  url: imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_) => const ColoredBox(color: AppTheme.navy),
                )
              else
                const ColoredBox(color: AppTheme.navy),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.navy.withValues(alpha: .9),
                      AppTheme.navy.withValues(alpha: .48),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 250,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MiniBadge(
                            icon: Icons.verified_outlined, text: 'Admin Ad'),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.08,
                              fontWeight: FontWeight.w800),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFFFEAD8),
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureAction extends StatelessWidget {
  const FeatureAction(
      {super.key,
      required this.icon,
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
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.deepRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: AppTheme.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 15, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniBadge extends StatelessWidget {
  const MiniBadge({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: .22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({super.key, required this.item, required this.onTap});

  final CategoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _serviceIcon(item.name);
    final asset = serviceAssetFor(item.name);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: .07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(asset, fit: BoxFit.cover),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppTheme.navy.withValues(alpha: .42),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:
                                  Icon(icon, color: AppTheme.saffron, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink)),
                  const SizedBox(height: 4),
                  Text(
                    item.description.isEmpty
                        ? 'Verified providers'
                        : item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceMiniCard extends StatelessWidget {
  const ServiceMiniCard({super.key, required this.item, required this.onTap});

  final CategoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _serviceIcon(item.name);
    return SizedBox(
      width: 94,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            children: [
              Ink(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.navy.withValues(alpha: .07),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(serviceAssetFor(item.name),
                          fit: BoxFit.cover),
                      ColoredBox(color: Colors.white.withValues(alpha: .18)),
                      Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: AppTheme.saffron, size: 21),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopPickServiceCard extends StatelessWidget {
  const TopPickServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 132,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(asset, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.navy.withValues(alpha: .88),
                        AppTheme.navy.withValues(alpha: .52),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 230,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.saffron,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              '24/7 Support',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  height: 1.12,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFFFFEAD8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 14,
                  bottom: 14,
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_forward,
                        size: 20, color: AppTheme.saffron),
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

IconData _serviceIcon(String value) {
  final text = value.toLowerCase();
  if (text.contains('pandit')) return Icons.temple_hindu_outlined;
  if (text.contains('electric')) return Icons.electrical_services_outlined;
  if (text.contains('plumb')) return Icons.plumbing_outlined;
  if (text.contains('carpent')) return Icons.handyman_outlined;
  if (text.contains('tutor')) return Icons.menu_book_outlined;
  if (text.contains('driver')) return Icons.local_taxi_outlined;
  if (text.contains('taxi') || text.contains('cab')) return Icons.local_taxi;
  if (text.contains('mover') || text.contains('delivery')) {
    return Icons.local_shipping_outlined;
  }
  if (text.contains('cook')) return Icons.restaurant_menu_outlined;
  if (text.contains('hotel')) return Icons.hotel_outlined;
  if (text.contains('restaurant') || text.contains('tiffin')) {
    return Icons.restaurant_outlined;
  }
  if (text.contains('clean')) return Icons.cleaning_services_outlined;
  if (text.contains('paint')) return Icons.format_paint_outlined;
  if (text.contains('ac')) return Icons.ac_unit_outlined;
  if (text.contains('beauty')) return Icons.spa_outlined;
  if (text.contains('legal') || text.contains('lawyer')) return Icons.gavel;
  if (text.contains('tax') ||
      text.contains('loan') ||
      text.contains('insurance')) {
    return Icons.account_balance_outlined;
  }
  if (text.contains('web') ||
      text.contains('digital') ||
      text.contains('cyber')) {
    return Icons.devices_outlined;
  }
  if (text.contains('property') || text.contains('rental')) {
    return Icons.real_estate_agent_outlined;
  }
  if (text.contains('hospital') || text.contains('medical')) {
    return Icons.local_hospital_outlined;
  }
  if (text.contains('construction') ||
      text.contains('architect') ||
      text.contains('interior') ||
      text.contains('furniture') ||
      text.contains('hardware')) {
    return Icons.construction_outlined;
  }
  if (text.contains('placement') || text.contains('job')) {
    return Icons.work_outline;
  }
  return Icons.home_repair_service_outlined;
}

IconData serviceIconFor(String value) => _serviceIcon(value);

String serviceAssetFor(String value) {
  final text = value.toLowerCase();
  if (text.contains('pandit')) return AppAssets.servicePandit;
  if (text.contains('hospital') ||
      text.contains('medical') ||
      text.contains('physio') ||
      text.contains('ambulance') ||
      text.contains('diagnostic')) {
    return AppAssets.categoryHospitalCare;
  }
  if (text.contains('property') || text.contains('rental')) {
    return AppAssets.categoryPropertyRent;
  }
  if (text.contains('hotel') ||
      text.contains('restaurant') ||
      text.contains('tiffin') ||
      text.contains('catering')) {
    return AppAssets.categoryFoodStay;
  }
  if (text.contains('taxi') ||
      text.contains('cab') ||
      text.contains('mover') ||
      text.contains('courier') ||
      text.contains('delivery') ||
      text.contains('travel')) {
    return AppAssets.categoryTransport;
  }
  if (text.contains('tax') ||
      text.contains('legal') ||
      text.contains('lawyer') ||
      text.contains('document') ||
      text.contains('loan') ||
      text.contains('insurance')) {
    return AppAssets.categoryLegalFinance;
  }
  if (text.contains('cyber') ||
      text.contains('printing') ||
      text.contains('xerox') ||
      text.contains('web') ||
      text.contains('app developer') ||
      text.contains('digital')) {
    return AppAssets.categoryItDigital;
  }
  if (text.contains('construction') ||
      text.contains('architect') ||
      text.contains('interior') ||
      text.contains('furniture') ||
      text.contains('hardware') ||
      text.contains('placement') ||
      text.contains('job')) {
    return AppAssets.categoryOtherServices;
  }
  if (text.contains('electric')) return AppAssets.serviceElectrician;
  if (text.contains('plumb')) return AppAssets.servicePlumber;
  if (text.contains('carpent')) return AppAssets.serviceCarpenter;
  if (text.contains('photograph')) return AppAssets.servicePhotographer;
  if (text.contains('computer')) return AppAssets.serviceComputerRepair;
  if (text.contains('mobile')) return AppAssets.serviceMobileRepair;
  if (text.contains('event')) return AppAssets.serviceEventManagement;
  if (text.contains('ac')) return AppAssets.serviceAcRepair;
  if (text.contains('clean')) return AppAssets.serviceCleaning;
  if (text.contains('paint')) return AppAssets.servicePainter;
  if (text.contains('tutor')) return AppAssets.serviceTutor;
  if (text.contains('driver')) return AppAssets.serviceDriver;
  if (text.contains('cook')) return AppAssets.serviceCook;
  if (text.contains('beauty')) return AppAssets.serviceBeauty;
  return AppAssets.logo;
}

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.stats});

  final Map<String, Object> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        for (final entry in stats.entries)
          PremiumCard(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.value.toString(),
                      style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepRed)),
                  const Spacer(),
                  Text(entry.key,
                      style: const TextStyle(
                          color: AppTheme.muted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!,
                style: const TextStyle(
                    color: AppTheme.muted, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class InfoStrip extends StatelessWidget {
  const InfoStrip({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.success, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key, required this.text, this.icon = Icons.inbox_outlined});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.deepRed, size: 38),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.muted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

const fallbackCategories = [
  CategoryItem(name: 'Pandit Ji', description: 'Puja, sanskar, path'),
  CategoryItem(name: 'Electrician', description: 'Repair aur fitting'),
  CategoryItem(name: 'Plumber', description: 'Water line service'),
  CategoryItem(name: 'Carpenter', description: 'Furniture repair'),
  CategoryItem(name: 'AC Repair', description: 'Cooling service'),
  CategoryItem(name: 'Cleaning', description: 'Home cleaning'),
  CategoryItem(name: 'Painter', description: 'Wall paint'),
  CategoryItem(name: 'Tutor', description: 'Home tuition'),
  CategoryItem(name: 'Driver', description: 'Local travel help'),
  CategoryItem(name: 'Cook', description: 'Ghar aur event cooking'),
  CategoryItem(name: 'Beauty', description: 'Salon at home'),
];
