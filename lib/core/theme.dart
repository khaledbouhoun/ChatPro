import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textGrey = Color(0xFF8E8E93);
  static const Color bg = Color(0xFF090E1A);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF151E2E);
  static const Color border = Color(0xFF1E2D42);
  static const Color accent = Color(0xFF3B82F6);
  static const Color aurora1 = Color(0xFF0EA5E9);
  static const Color aurora2 = Color(0xFF6366F1);
  static const Color textPrim = Color(0xFFF1F5F9);
  static const Color textSec = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color online = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color badge = Color(0xFF3B82F6);
  static const Color senderBg = Color(0xFF1A56DB);
  static const Color recvBg = Color(0xFF1C2535);
  static const Color warning = Color(0xFFF59E0B);
  static const Color replyBar = Color(0xFF0EA5E9);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryBlue,
      surface: surfaceDark,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textGrey),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: textGrey),
      floatingLabelStyle: const TextStyle(color: primaryBlue),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
