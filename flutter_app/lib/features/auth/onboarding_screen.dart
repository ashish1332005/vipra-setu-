import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../shared/app_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardingData(
      image: AppAssets.onboardingVipraSenaLogo,
      background: AppAssets.vipraSena,
      accent: AppTheme.saffron,
      title: 'Vipra Sena',
      headline: 'Ekta mein shakti, seva mein samarpan',
      subtitle:
          'Vipra samaj ko jodne, sahyog badhane aur samaj hit mein kaam karne ka ek majboot manch.',
      quote: 'Sangathit samaj, samruddh samaj',
      chips: [
        _ChipData(Icons.diversity_3_outlined, 'Sangathan'),
        _ChipData(Icons.volunteer_activism_outlined, 'Seva'),
        _ChipData(Icons.groups_2_outlined, 'Ekta'),
      ],
    ),
    _OnboardingData(
      image: AppAssets.onboardingBpfLogo,
      background: AppAssets.onboardingBpf,
      accent: Color(0xFF2563EB),
      title: 'BPF',
      headline: 'Ekta se vikas, seva se samman',
      subtitle:
          'Samaj seva, sahyog aur sanskar ke liye hum sab milkar ek kadam aage badhein.',
      quote: 'Samaj seva hi sachchi pooja hai',
      chips: [
        _ChipData(Icons.groups_outlined, 'Samaj Seva'),
        _ChipData(Icons.handshake_outlined, 'Sahyog'),
        _ChipData(Icons.account_balance_outlined, 'Sanskar'),
      ],
    ),
    _OnboardingData(
      image: AppAssets.onboardingParshuramLogo,
      background: AppAssets.parshuramHero,
      accent: Color(0xFFFF5A1F),
      title: 'Bhagwan Parshuram',
      headline: 'Dharma, sahas aur seva ka sangam',
      subtitle:
          'Bhagwan Parshuram ke adarshon se prerit hokar samaj mein dharma, sahas aur seva ko majboot banate hain.',
      quote: 'Dharma ki raksha, samaj ki seva',
      chips: [
        _ChipData(Icons.shield_outlined, 'Dharma'),
        _ChipData(Icons.groups_outlined, 'Sahas'),
        _ChipData(Icons.favorite_border, 'Seva'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color.lerp(const Color(0xFFFFF4EA), page.accent, .05)!,
              const Color(0xFFFFFBF7),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                _Header(accent: page.accent),
                const SizedBox(height: 18),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (_, index) => _OnboardingCard(
                      data: _pages[index],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _Dots(count: _pages.length, active: _index, color: page.accent),
                const SizedBox(height: 16),
                _ActionButton(
                  isLast: _index == _pages.length - 1,
                  color: page.accent,
                  onPressed: () {
                    if (_index == _pages.length - 1) {
                      widget.onDone();
                      return;
                    }
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 380;
    return Row(
      children: [
        CommunityMark(size: narrow ? 58 : 64, light: true),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vipra Sewa Setu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.navy,
                  fontSize: narrow ? 27 : 32,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Seva • Sahyog • Sanskar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: narrow ? 16 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: data.accent.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: .16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: compact ? 6 : 7,
            child: _Artwork(data: data),
          ),
          Expanded(
            flex: compact ? 7 : 6,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, compact ? 14 : 18, 20, 18),
              child: Column(
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: data.accent,
                      fontSize: compact ? 20 : 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      height: 1.06,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.subtitle,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF697386),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.42,
                    ),
                  ),
                  const Spacer(),
                  _ChipRow(chips: data.chips, color: data.accent),
                  const Spacer(),
                  _Quote(text: data.quote, color: data.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(data.background, fit: BoxFit.cover, alignment: Alignment.topCenter),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: .15),
                data.accent.withValues(alpha: .12),
                AppTheme.navy.withValues(alpha: .62),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 128,
            height: 128,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: data.accent.withValues(alpha: .85), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(data.image, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.chips, required this.color});

  final List<_ChipData> chips;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final chip in chips)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chip.icon, color: color, size: 23),
                    const SizedBox(height: 5),
                    Text(
                      chip.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          Icon(Icons.format_quote, color: color, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.active,
    required this.color,
  });

  final int count;
  final int active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == active ? 46 : 15,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: i == active ? color : const Color(0xFFE5E1DC),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.isLast,
    required this.color,
    required this.onPressed,
  });

  final bool isLast;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, const Color(0xFFFF7A00)]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          child: Row(
            children: [
              if (isLast) ...[
                const Icon(Icons.flag_outlined, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Text(
                isLast ? 'Get Started' : 'Next',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.image,
    required this.background,
    required this.accent,
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.quote,
    required this.chips,
  });

  final String image;
  final String background;
  final Color accent;
  final String title;
  final String headline;
  final String subtitle;
  final String quote;
  final List<_ChipData> chips;
}

class _ChipData {
  const _ChipData(this.icon, this.label);

  final IconData icon;
  final String label;
}
