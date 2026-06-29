import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vipra_setu_mobile/features/auth/splash_screen.dart';

void main() {
  testWidgets('shows Vipra Setu splash mark', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('Vipra Sewa Setu'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
