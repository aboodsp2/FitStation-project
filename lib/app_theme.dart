import 'package:flutter/material.dart';

class AppTheme {
  static const Color background   = Color(0xFFF5EFE6);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color primary      = Color(0xFF5C3D2E);
  static const Color primaryLight = Color(0xFF8B6351);
  static const Color accent       = Color(0xFFC9A87C);
  static const Color dark         = Color(0xFF1C1008);
  static const Color muted        = Color(0xFF9E8A7A);
  static const Color divider      = Color(0xFFE8DDD4);

  static const String _f = 'Poppins';

  static const TextStyle heading = TextStyle(
      fontFamily: _f, fontSize: 26, fontWeight: FontWeight.w700,
      color: dark, letterSpacing: 0.2);

  static const TextStyle subheading = TextStyle(
      fontFamily: _f, fontSize: 16, fontWeight: FontWeight.w600,
      color: dark, letterSpacing: 0.1);

  static const TextStyle body = TextStyle(
      fontFamily: _f, fontSize: 14, fontWeight: FontWeight.w400,
      color: muted, height: 1.5);

  static const TextStyle label = TextStyle(
      fontFamily: _f, fontSize: 11, color: muted,
      letterSpacing: 0.6, fontWeight: FontWeight.w500);

  // Apply this in MaterialApp(theme: AppTheme.theme)
  static ThemeData get theme => ThemeData(
    fontFamily: _f,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primary, secondary: accent, surface: surface,
    ),
    textTheme: const TextTheme(
      displayLarge:   TextStyle(fontFamily: _f, fontWeight: FontWeight.w700),
      displayMedium:  TextStyle(fontFamily: _f, fontWeight: FontWeight.w700),
      headlineLarge:  TextStyle(fontFamily: _f, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(fontFamily: _f, fontWeight: FontWeight.w600),
      titleLarge:     TextStyle(fontFamily: _f, fontWeight: FontWeight.w600),
      titleMedium:    TextStyle(fontFamily: _f, fontWeight: FontWeight.w600),
      bodyLarge:      TextStyle(fontFamily: _f, fontWeight: FontWeight.w400),
      bodyMedium:     TextStyle(fontFamily: _f, fontWeight: FontWeight.w400),
      labelLarge:     TextStyle(fontFamily: _f, fontWeight: FontWeight.w500),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background, elevation: 0,
      titleTextStyle: TextStyle(fontFamily: _f, fontWeight: FontWeight.w600,
          fontSize: 18, color: dark),
      iconTheme: IconThemeData(color: dark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontFamily: _f, fontWeight: FontWeight.w700)),
    ),
  );

  static BoxDecoration card({double radius = 20}) => BoxDecoration(
    color: surface, borderRadius: BorderRadius.circular(radius),
    boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.07),
        blurRadius: 16, offset: const Offset(0, 5))],
  );

  static InputDecoration inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: _f, color: muted, fontSize: 14),
        prefixIcon: Icon(icon, color: accent, size: 20),
        filled: true, fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accent, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: divider, width: 1)),
      );
}
