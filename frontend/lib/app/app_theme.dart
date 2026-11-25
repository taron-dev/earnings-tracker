import 'package:flutter/material.dart';

/// The app's brand blue, used for actions and work in progress.
const brandColor = Color(0xFF275DAD);

/// The bundled Plus Jakarta Sans (`assets/fonts/`).
const appFontFamily = 'PlusJakartaSans';

/// Digits of equal width, so amounts and times do not shift sideways when they change.
const tabularFigures = [FontFeature.tabularFigures()];

/// Colors of the redesign that Material's [ColorScheme] has no slot for, in a light and a dark set.
/// Screens read them with `AppColors.of(context)`, never as hex values of their own.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.card,
    required this.cardBorder,
    required this.divider,
    required this.text,
    required this.textSecondary,
    required this.textFaint,
    required this.accent,
    required this.accentFill,
    required this.onAccentFill,
    required this.earned,
    required this.earnedContainer,
    required this.chipBorder,
    required this.track,
    required this.pill,
    required this.uncoveredRing,
    required this.softButton,
    required this.navigationShadow,
    required this.fabShadow,
  });

  /// Page background, behind the cards.
  final Color background;
  final Color card;
  final Color cardBorder;

  /// Line between rows inside a card.
  final Color divider;
  final Color text;
  final Color textSecondary;

  /// Chevrons and other hints that need not be read.
  final Color textFaint;

  /// Actions, the active tab and work in progress, as text or a thin mark.
  final Color accent;

  /// Large blue areas with text on them: the next milestone card and the "+" button.
  final Color accentFill;
  final Color onAccentFill;

  /// Earnings and covered items.
  final Color earned;
  final Color earnedContainer;

  /// Outline of chips and outlined buttons.
  final Color chipBorder;

  /// Unfilled part of a progress bar.
  final Color track;

  /// Gray pill behind a worked time.
  final Color pill;

  /// Empty circle of an uncovered item.
  final Color uncoveredRing;

  /// Background of secondary buttons such as −30m and the quick choices.
  final Color softButton;
  final Color navigationShadow;
  final Color fabShadow;

  static const light = AppColors(
    background: Color(0xFFF4F6FB),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE4E8F1),
    divider: Color(0xFFEEF1F6),
    text: Color(0xFF10172A),
    textSecondary: Color(0xFF5B6478),
    textFaint: Color(0xFF8A93A6),
    accent: brandColor,
    accentFill: brandColor,
    onAccentFill: Color(0xFFFFFFFF),
    earned: Color(0xFF15803D),
    earnedContainer: Color(0xFFE7F6EC),
    chipBorder: Color(0xFFD9DEEA),
    track: Color(0xFFE8ECF4),
    pill: Color(0xFFEEF1F6),
    uncoveredRing: Color(0xFFC5CCDA),
    softButton: Color(0xFFF4F6FB),
    navigationShadow: Color(0x1A10172A),
    fabShadow: Color(0x59275DAD),
  );

  /// Same shapes on a dark background with cards one step lighter. Blue and green are lighter than in
  /// the light set, so as text on a card they keep a contrast of at least 4.5:1; the filled blue stays
  /// dark enough for white text on it.
  static const dark = AppColors(
    background: Color(0xFF0D1220),
    card: Color(0xFF161C2B),
    cardBorder: Color(0xFF262E40),
    divider: Color(0xFF222A3A),
    text: Color(0xFFE6EAF2),
    textSecondary: Color(0xFFA1AABD),
    textFaint: Color(0xFF6E7890),
    accent: Color(0xFF86AEF0),
    accentFill: Color(0xFF2F63B3),
    onAccentFill: Color(0xFFFFFFFF),
    earned: Color(0xFF4ADE80),
    earnedContainer: Color(0xFF11301F),
    chipBorder: Color(0xFF323B50),
    track: Color(0xFF262E40),
    pill: Color(0xFF232B3D),
    uncoveredRing: Color(0xFF4A5468),
    softButton: Color(0xFF1D2435),
    navigationShadow: Color(0x66000000),
    fabShadow: Color(0x66000000),
  );

  /// The set of the current theme; outside [appTheme] (a bare `MaterialApp` in a test) the one matching
  /// its brightness.
  static AppColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColors>() ?? (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      card: mix(card, other.card),
      cardBorder: mix(cardBorder, other.cardBorder),
      divider: mix(divider, other.divider),
      text: mix(text, other.text),
      textSecondary: mix(textSecondary, other.textSecondary),
      textFaint: mix(textFaint, other.textFaint),
      accent: mix(accent, other.accent),
      accentFill: mix(accentFill, other.accentFill),
      onAccentFill: mix(onAccentFill, other.onAccentFill),
      earned: mix(earned, other.earned),
      earnedContainer: mix(earnedContainer, other.earnedContainer),
      chipBorder: mix(chipBorder, other.chipBorder),
      track: mix(track, other.track),
      pill: mix(pill, other.pill),
      uncoveredRing: mix(uncoveredRing, other.uncoveredRing),
      softButton: mix(softButton, other.softButton),
      navigationShadow: mix(navigationShadow, other.navigationShadow),
      fabShadow: mix(fabShadow, other.fabShadow),
    );
  }
}

/// Corner radius of cards.
const double cardRadius = 20;

/// Material 3 theme built from [AppColors]: Plus Jakarta Sans, white bordered cards without shadow
/// on a light gray background, brand blue for actions.
ThemeData appTheme(Brightness brightness) {
  final colors = brightness == Brightness.light ? AppColors.light : AppColors.dark;
  final seeded = ColorScheme.fromSeed(
    seedColor: brandColor,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  final scheme = seeded.copyWith(
    primary: colors.accent,
    onPrimary: brightness == Brightness.light ? Colors.white : colors.background,
    surface: colors.card,
    onSurface: colors.text,
    onSurfaceVariant: colors.textSecondary,
    outline: colors.chipBorder,
    outlineVariant: colors.cardBorder,
    surfaceContainerLowest: colors.card,
    surfaceContainerLow: colors.card,
    surfaceContainer: colors.card,
    surfaceContainerHigh: colors.card,
    surfaceContainerHighest: colors.pill,
  );
  final base = ThemeData(colorScheme: scheme, fontFamily: appFontFamily);
  final textTheme = _withTabularFigures(
    base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleLarge: base.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
      titleMedium: base.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
      titleSmall: base.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
      labelLarge: base.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: base.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
    ),
  ).apply(bodyColor: colors.text, displayColor: colors.text);
  const buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)));
  const buttonText = TextStyle(fontFamily: appFontFamily, fontSize: 15, fontWeight: FontWeight.w700);
  return base.copyWith(
    scaffoldBackgroundColor: colors.background,
    textTheme: textTheme,
    extensions: [colors],
    // Material 3 turns the app bar surfaceContainer when content scrolls under it; in the centered column
    // that ends at the column's edges as a gray strip, so the app bar keeps the background color instead.
    appBarTheme: AppBarThemeData(
      backgroundColor: colors.background,
      foregroundColor: colors.text,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: appFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: colors.text,
        fontFeatures: tabularFigures,
      ),
      actionsIconTheme: IconThemeData(color: colors.textSecondary),
    ),
    cardTheme: CardThemeData(
      color: colors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: colors.cardBorder),
      ),
    ),
    dividerTheme: DividerThemeData(color: colors.divider, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: buttonShape,
        textStyle: buttonText,
        backgroundColor: colors.accentFill,
        foregroundColor: colors.onAccentFill,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: buttonShape,
        textStyle: buttonText,
        side: BorderSide(color: colors.chipBorder),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: buttonText)),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: colors.chipBorder,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(backgroundColor: colors.card, surfaceTintColor: Colors.transparent),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.accent,
      linearTrackColor: colors.track,
      linearMinHeight: 6,
      borderRadius: BorderRadius.circular(3),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.chipBorder),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.accentFill,
      foregroundColor: colors.onAccentFill,
      elevation: 2,
      extendedTextStyle: buttonText,
    ),
    listTileTheme: ListTileThemeData(iconColor: colors.textSecondary),
  );
}

TextTheme _withTabularFigures(TextTheme theme) {
  TextStyle? tabular(TextStyle? style) => style?.copyWith(fontFeatures: tabularFigures);
  return theme.copyWith(
    displayLarge: tabular(theme.displayLarge),
    displayMedium: tabular(theme.displayMedium),
    displaySmall: tabular(theme.displaySmall),
    headlineLarge: tabular(theme.headlineLarge),
    headlineMedium: tabular(theme.headlineMedium),
    headlineSmall: tabular(theme.headlineSmall),
    titleLarge: tabular(theme.titleLarge),
    titleMedium: tabular(theme.titleMedium),
    titleSmall: tabular(theme.titleSmall),
    bodyLarge: tabular(theme.bodyLarge),
    bodyMedium: tabular(theme.bodyMedium),
    bodySmall: tabular(theme.bodySmall),
    labelLarge: tabular(theme.labelLarge),
    labelMedium: tabular(theme.labelMedium),
    labelSmall: tabular(theme.labelSmall),
  );
}
