import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls the tab's list to its end and checks that [lastRow] ends above
/// the floating "+" button, so nothing stays hidden under it.
Future<void> expectLastRowClearOfFab(
  WidgetTester tester,
  Finder lastRow,
) async {
  final list = find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;
  final position = tester.state<ScrollableState>(list).position;
  // A lazy list only estimates its length until the last rows are built, so jump until the end stops moving.
  double end;
  do {
    end = position.maxScrollExtent;
    position.jumpTo(end);
    await tester.pumpAndSettle();
  } while (position.maxScrollExtent != end);

  expect(
    position.maxScrollExtent,
    greaterThan(0),
    reason: 'the list must be longer than the screen',
  );
  final fabTop = tester.getRect(find.byType(FloatingActionButton)).top;
  expect(tester.getRect(lastRow).bottom, lessThanOrEqualTo(fabTop));
}
