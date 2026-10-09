import 'package:flutter/material.dart';

/// App color palette — deep OLED pitch black with neon green streaming accents
class AppColors {
  AppColors._();

  // Backgrounds — True 100% OLED deep pitch black
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0C0D0F);
  static const Color surfaceLight = Color(0xFF14161C);
  static const Color card = Color(0xFF111216);
  static const Color bottomNav = Color(0xFF08090B);
  static const Color floatingNav = Color(0xF208090C);
  static const Color floatingNavBorder = Color(0x3300E676);

  // Genre & filter chip colors
  static const Color chipSelected = Color(0xFF00E676);
  static const Color chipUnselected = Color(0xFF121419);
  static const Color chipTextUnselected = Color(0xFFD0D4DF);
  static const Color chipTextSelected = Color(0xFF000000);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9AA0B0);
  static const Color textHint = Color(0xFF555B6B);

  // Accent — Vibrant Electric Streaming Green & FreeWatch Red
  static const Color primary = Color(0xFFFF4B26);
  static const Color accent = Color(0xFF00E676);
  static const Color accentDark = Color(0xFF00B050);
  static const Color accentLight = Color(0xFF69F0AE);
  static const Color accentGlow = Color(0x3300E676);

  // Other Accents
  static const Color star = Color(0xFFFFB800);

  // Divider / border
  static const Color divider = Color(0xFF161922);
}
