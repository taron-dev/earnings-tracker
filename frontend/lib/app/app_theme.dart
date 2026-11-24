import 'package:flutter/material.dart';

/// The app's brand blue; Material 3 derives the rest of the palette from it.
const brandColor = Color(0xFF275DAD);

/// Material 3 theme seeded by [brandColor]; secondary and tertiary colors are derived to match.
/// The fidelity variant keeps the seed's saturation (the default tonal spot would mute it). The light
/// scheme uses the brand color itself as primary (the seeded tone is darker, #004591); the dark scheme
/// keeps its lighter seeded blue, since #275DAD on a dark surface has too little contrast.
ThemeData appTheme(Brightness brightness) {
  final seeded = ColorScheme.fromSeed(
    seedColor: brandColor,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  final scheme = brightness == Brightness.light ? seeded.copyWith(primary: brandColor) : seeded;
  return ThemeData(
    colorScheme: scheme,
    // Material 3 turns the app bar surfaceContainer when content scrolls under it; in the centered column
    // that ends at the column's edges as a gray strip, so the app bar keeps the background color instead.
    appBarTheme: AppBarThemeData(backgroundColor: scheme.surface, scrolledUnderElevation: 0),
  );
}
