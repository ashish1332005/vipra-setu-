import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vipra_setu_mobile/features/auth/onboarding_screen.dart';
import 'package:vipra_setu_mobile/features/auth/splash_screen.dart';
import 'package:vipra_setu_mobile/shared/app_widgets.dart';

void main() {
  testWidgets('shows branded Vipra Setu splash', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('Vipra Sewa Setu'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.image(const AssetImage(AppAssets.logo)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash fits a compact phone in dark mode', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    ));

    expect(find.text('Vipra Sewa Setu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding fits a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: OnboardingScreen(onDone: () {})));
    await tester.pump();

    expect(find.text('Vipra Sewa Setu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
