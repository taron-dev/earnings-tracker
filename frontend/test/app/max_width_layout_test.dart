import 'package:earnings_tracker/app/max_width_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpOnScreen(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MaxWidthLayout(child: child!),
        home: const Scaffold(body: Text('obsah')),
      ),
    );
  }

  testWidgets('limits the app to the max width on a wide screen', (
    tester,
  ) async {
    await pumpOnScreen(tester, const Size(1920, 1080));

    final scaffold = tester.getRect(find.byType(Scaffold));
    expect(scaffold.width, appMaxWidth);
    expect(scaffold.center.dx, 960);
  });

  testWidgets('uses the full width on a phone', (tester) async {
    await pumpOnScreen(tester, const Size(400, 800));

    expect(tester.getSize(find.byType(Scaffold)).width, 400);
  });
}
