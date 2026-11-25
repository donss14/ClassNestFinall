import 'package:flutter/material.dart';

/// Modern Minimalist: clean, contemporary grayscale with DejaVuSans type.
class AppTheme {
  AppTheme._();

  static const Color charcoal = Color(0xFF36454F);
  static const Color slateGray = Color(0xFF708090);
  static const Color lightGray = Color(0xFFD3D3D3);
  static const Color white = Color(0xFFFFFFFF);

  static const String _fontFamily = 'DejaVuSans';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: charcoal,
      brightness: Brightness.light,
    ).copyWith(
      primary: charcoal,
      onPrimary: white,
      secondary: slateGray,
      onSecondary: white,
      surface: white,
      onSurface: charcoal,
      onSurfaceVariant: slateGray,
      outline: slateGray,
      outlineVariant: lightGray,
      surfaceContainerHighest: lightGray,
      primaryContainer: lightGray,
      onPrimaryContainer: charcoal,
      secondaryContainer: lightGray,
      onSecondaryContainer: charcoal,
    );
    return _build(scheme, scaffold: white);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: charcoal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: lightGray,
      onPrimary: charcoal,
      secondary: slateGray,
      onSecondary: white,
      surface: charcoal,
      onSurface: white,
      onSurfaceVariant: lightGray,
      outline: slateGray,
      outlineVariant: slateGray,
      primaryContainer: slateGray,
      onPrimaryContainer: white,
      secondaryContainer: slateGray,
      onSecondaryContainer: white,
    );
    return _build(scheme, scaffold: charcoal);
  }

  static ThemeData _build(ColorScheme scheme, {required Color scaffold}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: _fontFamily,
    );

    // Headers use DejaVuSans Bold, body text uses DejaVuSans regular.
    final text = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
      displayMedium: base.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
      displaySmall: base.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.brightness == Brightness.light
            ? lightGray
            : slateGray,
      ),
    );
  }
}
