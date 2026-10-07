import 'package:earnings_tracker/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offers Google and magic link sign-in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Prihlásiť sa cez Google'), findsOneWidget);
    expect(find.text('Poslať prihlasovací odkaz'), findsOneWidget);
  });
}
