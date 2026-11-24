import 'dart:math';

import 'package:flutter/material.dart';

/// Where the Material 3 "compact" window size class ends, i.e. phone width,
/// which every screen of this app is designed for.
const double phoneWidth = 600;

/// Width of the app column on a window of [screenWidth]: the whole window on
/// a phone, half of it on a monitor, but never narrower than [phoneWidth].
/// Decided by the window width, not by the device, so a narrow browser
/// window on a PC behaves like a phone.
double appColumnWidth(double screenWidth) => min(screenWidth, max(phoneWidth, screenWidth / 2));

/// Centers the whole app in a column of [appColumnWidth]; the space on the
/// sides has the scaffold background, so the window looks like one app with
/// no visible edge. Wraps the Navigator, so dialogs and bottom sheets stay in
/// the column too.
class MaxWidthLayout extends StatelessWidget {
  const MaxWidthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: SizedBox(width: appColumnWidth(constraints.maxWidth), child: child),
        ),
      ),
    );
  }
}
