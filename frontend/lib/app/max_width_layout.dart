import 'package:flutter/material.dart';

/// Upper bound for the app width on large screens. 600 dp is where the
/// Material 3 "compact" window size class ends, i.e. phone width, which is
/// what every screen of this app is designed for.
const double appMaxWidth = 600;

/// Centers the whole app in a column of at most [appMaxWidth]; the space
/// on the sides gets the theme surface color. Wraps the Navigator, so
/// dialogs and bottom sheets stay in the column too.
class MaxWidthLayout extends StatelessWidget {
  const MaxWidthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: appMaxWidth),
          child: child,
        ),
      ),
    );
  }
}
