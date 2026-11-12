import 'package:earnings_tracker/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offers Google and magic link sign-in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Prihlásiť sa cez Google'), findsOneWidget);
    expect(find.text('Poslať prihlasovací odkaz'), findsOneWidget);
  });

  testWidgets('tells the user when the session expired', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage(sessionExpired: true)));

    expect(find.text('Prihlásenie vypršalo, prihlás sa znova.'), findsOneWidget);
  });

  testWidgets('says nothing about expiry on a regular sign-in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.textContaining('vypršalo'), findsNothing);
  });
}
