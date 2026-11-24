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

  testWidgets('takes half of a monitor, centered', (tester) async {
    await pumpOnScreen(tester, const Size(1920, 1080));

    final scaffold = tester.getRect(find.byType(Scaffold));
    expect(scaffold.width, 960);
    expect(scaffold.center.dx, 960);
  });

  testWidgets('stays phone wide where half would be narrower', (tester) async {
    await pumpOnScreen(tester, const Size(1000, 800));

    final scaffold = tester.getRect(find.byType(Scaffold));
    expect(scaffold.width, phoneWidth);
    expect(scaffold.center.dx, 500);
  });

  testWidgets('uses the full width on a phone', (tester) async {
    await pumpOnScreen(tester, const Size(400, 800));

    expect(tester.getSize(find.byType(Scaffold)).width, 400);
  });

  testWidgets('fills the sides with the app background', (tester) async {
    await pumpOnScreen(tester, const Size(1920, 1080));

    final sides = tester.widget<ColoredBox>(
      find.descendant(of: find.byType(MaxWidthLayout), matching: find.byType(ColoredBox)).first,
    );
    final context = tester.element(find.byType(Scaffold));
    expect(sides.color, Theme.of(context).scaffoldBackgroundColor);
  });
}
