import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData light = _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0D9488),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDBF5F2),
      onPrimaryContainer: Color(0xFF0D9488),
      secondary: Color(0xFFF59E0B),
      onSecondary: Color(0xFF1C1917),
      secondaryContainer: Color(0xFFFBEBD0),
      onSecondaryContainer: Color(0xFF1C2B2A),
      error: Color(0xFFB91C1C),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1C2B2A),
      onSurfaceVariant: Color(0xFF6B7573),
      outline: Color(0xFFA8A293),
      outlineVariant: Color(0xFFDDD8CA),
      surfaceContainerHighest: Color(0xFFEBE7DC),
    ),
    const Color(0xFFF8FAFC),
  );

  static final ThemeData dark = _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF56F5E7),
      onPrimary: Color(0xFF0A2926),
      primaryContainer: Color(0xFF183936),
      onPrimaryContainer: Color(0xFF56F5E7),
      secondary: Color(0xFFFCB236),
      onSecondary: Color(0xFF1C1917),
      secondaryContainer: Color(0xFF3F2F12),
      onSecondaryContainer: Color(0xFFEEF5F3),
      error: Color(0xFFF87171),
      onError: Color(0xFF1C1917),
      surface: Color(0xFF162826),
      onSurface: Color(0xFFEEF5F3),
      onSurfaceVariant: Color(0xFF9BB0AC),
      outline: Color(0xFF5F7773),
      outlineVariant: Color(0xFF2F4A46),
      surfaceContainerHighest: Color(0xFF27403D),
    ),
    const Color(0xFF0E1B1A),
  );

  static ThemeData _build(ColorScheme cs, Color bg) {
    final base = ThemeData(useMaterial3: true, colorScheme: cs);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    );
  }
}