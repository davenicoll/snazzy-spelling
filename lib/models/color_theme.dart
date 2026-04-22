import 'package:flutter/material.dart';

enum ColorTheme {
  snazzy(
    label: 'Snazzy',
    seedColor: Color(0xFF6DD528),
    correctColor: Color(0xFF2E7D32),
    incorrectColor: Color(0xFFBA1A1A),
  ),
  starBrawls(
    label: 'Star Brawls',
    seedColor: Color(0xFF2E36F3),
    correctColor: Color(0xFF159E85),
    incorrectColor: Color(0xFFFF003D),
  ),
  cellSuper(
    label: 'Cell Super',
    seedColor: Color(0xFFAA00DD),
    correctColor: Color(0xFF6DD528),
    incorrectColor: Color(0xFFFF003B),
  );

  const ColorTheme({
    required this.label,
    required this.seedColor,
    required this.correctColor,
    required this.incorrectColor,
  });

  final String label;
  final Color seedColor;
  final Color correctColor;
  final Color incorrectColor;

  ColorScheme buildColorScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      contrastLevel: 0.5,
    );

    switch (this) {
      case ColorTheme.snazzy:
        if (brightness == Brightness.dark) {
          return base.copyWith(
            primary: const Color(0xFF6DD528),
            onPrimary: Colors.black,
            // Softer, less-saturated green than the seed so accent usages
            // (e.g. the "hide completed" unchecked icon, the Check key) read
            // as on-palette without being aggressive on a dark surface.
            tertiary: const Color(0xFF9FD48A),
            onTertiary: Colors.black,
          );
        }
        return base.copyWith(
          // Deeper, lower-chroma green for the light palette — same intent as
          // the dark override: on-brand green without the over-saturated
          // seed-derived shade the default `fromSeed` tertiary picks.
          tertiary: const Color(0xFF4E7A3A),
          onTertiary: Colors.white,
        );

      case ColorTheme.starBrawls:
        if (brightness == Brightness.dark) {
          return base.copyWith(
            primary: const Color(0xFFF161DC),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFF8A0070),
            onPrimaryContainer: const Color(0xFFFFD6F4),
            secondary: const Color(0xFFFFED45),
            onSecondary: Colors.black,
            secondaryContainer: const Color(0xFF169D83),
            onSecondaryContainer: const Color(0xFFC4F624),
            tertiary: const Color(0xFFF28125),
            onTertiary: Colors.white,
            error: incorrectColor,
            onError: Colors.white,
            surface: const Color(0xFF2E36F3),
            onSurface: Colors.white,
            surfaceContainerLowest: const Color(0xFF1A20B0),
            surfaceContainerLow: const Color(0xFF2228D0),
            surfaceContainer: const Color(0xFF2830E0),
            surfaceContainerHigh: const Color(0xFF3A42F5),
            surfaceContainerHighest: const Color(0xFF4C54FF),
            outline: const Color(0xFF8888FF),
            outlineVariant: const Color(0xFF5058FF),
          );
        } else {
          return base.copyWith(
            primary: const Color(0xFFC020A0),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFFFD6F4),
            onPrimaryContainer: const Color(0xFF5C004C),
            secondary: const Color(0xFFB8A000),
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFFFED45),
            onSecondaryContainer: const Color(0xFF3D3500),
            tertiary: const Color(0xFFF28125),
            onTertiary: Colors.white,
            error: incorrectColor,
            onError: Colors.white,
          );
        }

      case ColorTheme.cellSuper:
        if (brightness == Brightness.dark) {
          return base.copyWith(
            primary: const Color(0xFFE525C8),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFF6A0090),
            onPrimaryContainer: const Color(0xFFF0D0FF),
            secondary: const Color(0xFFF5C935),
            onSecondary: Colors.black,
            secondaryContainer: const Color(0xFFE527C7),
            onSecondaryContainer: Colors.white,
            tertiary: const Color(0xFFE426C6),
            onTertiary: Colors.white,
            error: incorrectColor,
            onError: Colors.white,
            surface: const Color(0xFF922EF3),
            onSurface: Colors.white,
            surfaceContainerLowest: const Color(0xFF5A1AAA),
            surfaceContainerLow: const Color(0xFF6E20C4),
            surfaceContainer: const Color(0xFF7E26D8),
            surfaceContainerHigh: const Color(0xFF9A34F5),
            surfaceContainerHighest: const Color(0xFFAA50FF),
            outline: const Color(0xFFCC88FF),
            outlineVariant: const Color(0xFF9955DD),
          );
        } else {
          return base.copyWith(
            primary: const Color(0xFFB010A0),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFFFD0F8),
            onPrimaryContainer: const Color(0xFF500048),
            secondary: const Color(0xFFA09000),
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFF5C935),
            onSecondaryContainer: const Color(0xFF3D3500),
            tertiary: const Color(0xFFE426C6),
            onTertiary: Colors.white,
            error: incorrectColor,
            onError: Colors.white,
          );
        }
    }
  }

  String toStorageString() => name;

  static ColorTheme fromStorageString(String? value) {
    for (final theme in ColorTheme.values) {
      if (theme.name == value) return theme;
    }
    return ColorTheme.snazzy;
  }
}
