import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/app_widgets.dart';
import 'taker_catalog.dart';

class TakerShellBackground extends StatelessWidget {
  const TakerShellBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3E8), Colors.white, Color(0xFFFFFAF5)],
          ),
        ),
        child: child,
      ),
    );
  }
}

class TakerPageHeader extends StatelessWidget {
  const TakerPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.name,
    this.showBack = false,
    this.onBack,
    this.onSearch,
    this.onNotificationTap,
  });

  final String title;
  final String? subtitle;
  final String? name;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final displayTitle = name == null ? title : 'Namaste $name';
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 520;
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.saffron.withValues(alpha: .09),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
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
                    Colors.white.withValues(alpha: .96),
                    const Color(0xFFFFF3E8).withValues(alpha: .84),
                    Colors.white.withValues(alpha: .46),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 22,
              topInset + (compact ? 18 : 22),
              compact ? 16 : 22,
              compact ? 18 : 22,
            ),
            child: Row(
              children: [
                if (showBack) ...[
                  _SoftIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: onBack ?? () => Navigator.maybePop(context),
                    compact: compact,
                  ),
                  SizedBox(width: compact ? 10 : 14),
                ] else if (name != null) ...[
                  CommunityMark(size: compact ? 50 : 60),
                  SizedBox(width: compact ? 10 : 13),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: compact ? 23 : 27,
                          height: 1.08,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          if (name != null)
                            const Icon(Icons.location_on,
                                color: AppTheme.saffron, size: 18),
                          if (name != null) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle ?? 'Bhilwara, Rajasthan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: compact ? 13 : 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _NotificationButton(
                  onTap: onNotificationTap ?? () {},
                  compact: compact,
                ),
                if (onSearch != null) ...[
                  SizedBox(width: compact ? 6 : 10),
                  _SoftIconButton(
                      icon: Icons.search, onTap: onSearch!, compact: compact),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullBleedHeader extends StatelessWidget {
  const FullBleedHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Transform.translate(
      offset: const Offset(-16, 0),
      child: SizedBox(
        width: width,
        child: child,
      ),
    );
  }
}

class TakerWelcomePanel extends StatelessWidget {
  const TakerWelcomePanel({
    super.key,
    required this.name,
    required this.onSearchTap,
    required this.onNotificationTap,
    this.onVoiceSearchTap,
  });

  final String name;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final VoidCallback? onVoiceSearchTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 520;
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.saffron.withValues(alpha: .1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
                    Colors.white.withValues(alpha: .96),
                    const Color(0xFFFFF3E8).withValues(alpha: .86),
                    Colors.white.withValues(alpha: .42),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 22,
              topInset + (compact ? 18 : 22),
              compact ? 16 : 22,
              compact ? 14 : 18,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CommunityMark(size: compact ? 50 : 60),
                    SizedBox(width: compact ? 10 : 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Namaste $name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.ink,
                              fontSize: compact ? 22 : 26,
                              height: 1.08,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppTheme.saffron, size: 18),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Bhilwara, Rajasthan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: compact ? 13 : 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _NotificationButton(
                      onTap: onNotificationTap,
                      compact: compact,
                    ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 18),
                TakerSearchBar(
                  onTap: onSearchTap,
                  onVoiceTap: onVoiceSearchTap,
                  compact: true,
                  elevated: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeritageLineArt extends StatelessWidget {
  const HeritageLineArt({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _HeritagePainter()));
  }
}

class _HeritagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.saffron.withValues(alpha: .2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final baseY = size.height * .72;
    for (var i = 0; i < 5; i++) {
      final cx = size.width * (.48 + i * .095);
      final w = 36.0 - i * 2;
      final h = 42.0 - i * 3;
      final rect =
          Rect.fromCenter(center: Offset(cx, baseY), width: w, height: h);
      canvas.drawArc(rect, 3.14, 3.14, false, paint);
      canvas.drawRect(
        Rect.fromLTWH(cx - w / 2, baseY, w, h * .42),
        paint,
      );
      canvas.drawLine(
          Offset(cx, baseY - h / 2 - 8), Offset(cx, baseY - h / 2), paint);
    }
    final ground = Path()
      ..moveTo(size.width * .42, baseY + 19)
      ..quadraticBezierTo(size.width * .7, baseY + 36, size.width, baseY + 14);
    canvas.drawPath(ground, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TakerSearchBar extends StatelessWidget {
  const TakerSearchBar({
    super.key,
    required this.onTap,
    this.onVoiceTap,
    this.compact = false,
    this.elevated = true,
  });

  final VoidCallback onTap;
  final VoidCallback? onVoiceTap;
  final bool compact;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 24 : 32),
      elevation: elevated ? 10 : 0,
      shadowColor: AppTheme.saffron.withValues(alpha: .18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 24 : 32),
        child: Container(
          height: compact ? 56 : 60,
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(compact ? 24 : 32),
            border: Border.all(color: const Color(0xFFFFD7C6)),
            boxShadow: elevated
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.navy.withValues(alpha: .07),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: narrow ? 25 : 30, color: Colors.black),
              SizedBox(width: narrow ? 10 : 14),
              Expanded(
                child: Text(
                  'Search Services...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: narrow ? 14 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!narrow || !compact || onVoiceTap != null) ...[
                IconButton(
                  onPressed: onVoiceTap,
                  icon: Icon(Icons.mic_none,
                      size: narrow ? 25 : 30, color: AppTheme.saffron),
                  tooltip: 'Voice search',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(width: narrow ? 34 : 40),
                ),
                Container(
                  height: 34,
                  width: 1,
                  margin: EdgeInsets.symmetric(horizontal: narrow ? 10 : 15),
                  color: AppTheme.line,
                ),
              ],
              Icon(Icons.tune, color: AppTheme.saffron, size: narrow ? 24 : 28),
            ],
          ),
        ),
      ),
    );
  }
}

class TakerSectionHeader extends StatelessWidget {
  const TakerSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 22,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w700,
              ).copyWith(fontSize: narrow ? 20 : 22),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.saffron,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_forward_ios, size: 15),
                  const SizedBox(width: 7),
                  Text(actionLabel!, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ServiceIconTile extends StatelessWidget {
  const ServiceIconTile({super.key, required this.item, required this.onTap});

  final ServiceCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final accent = _serviceAccent(item.name);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF4E7DE)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: .055),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: narrow ? 8 : 12,
              vertical: narrow ? 12 : 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: narrow ? 54 : 64,
                  height: narrow ? 54 : 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.tint,
                        Color.lerp(item.tint, Colors.white, .38)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .13),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .64),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Icon(item.icon, color: accent, size: narrow ? 27 : 31),
                    ],
                  ),
                ),
                SizedBox(height: narrow ? 10 : 13),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    height: 1.05,
                    fontSize: narrow ? 11 : 13,
                    fontWeight: FontWeight.w800,
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

Color _serviceAccent(String value) {
  final text = value.toLowerCase();
  if (text.contains('pandit')) return AppTheme.saffron;
  if (text.contains('electric')) return const Color(0xFFFF7A1A);
  if (text.contains('plumb')) return const Color(0xFF2F80ED);
  if (text.contains('carpent')) return const Color(0xFFE7652C);
  if (text.contains('ac')) return const Color(0xFF16A7C8);
  if (text.contains('clean')) return AppTheme.success;
  if (text.contains('paint')) return const Color(0xFFE95F45);
  if (text.contains('driver')) return const Color(0xFFE64B3C);
  if (text.contains('photo')) return const Color(0xFF7C5CFF);
  if (text.contains('mobile')) return const Color(0xFFE04885);
  return AppTheme.saffron;
}

class ServiceImageCard extends StatelessWidget {
  const ServiceImageCard({super.key, required this.item, required this.onTap});

  final ServiceCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final asset = serviceAssetFor(item.name);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.line),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navy.withValues(alpha: .06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(narrow ? 8 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.55,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          asset,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              color: _serviceAccent(item.name),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: narrow ? 16 : 18,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: narrow ? 12 : 13,
                    fontWeight: FontWeight.w800,
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.verified_outlined,
                        color: AppTheme.emerald, size: narrow ? 15 : 16),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Verified providers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  const _SoftIconButton(
      {required this.icon, required this.onTap, this.compact = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(compact ? 15 : 17),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 15 : 17),
        onTap: onTap,
        child: SizedBox(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            child: Icon(icon, size: compact ? 23 : 26)),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _SoftIconButton(
            icon: Icons.notifications_none, onTap: onTap, compact: compact),
        Positioned(
          right: -3,
          top: -5,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: AppTheme.saffron,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
