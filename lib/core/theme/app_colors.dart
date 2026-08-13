import 'package:flutter/material.dart';

/// Centralized color system for HabitFlow.
/// Keeping every color in one place makes it trivial to re-theme the app
/// and keeps light/dark mode consistent across every screen.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF5B6CFF);
  static const Color primaryDark = Color(0xFF4453E0);
  static const Color accent = Color(0xFF22C7B5);

  // Status
  static const Color success = Color(0xFF32D583);
  static const Color warning = Color(0xFFFFAB2E);
  static const Color error = Color(0xFFF04438);
  static const Color info = Color(0xFF4C9EFF);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE7E9F3);
  static const Color lightTextPrimary = Color(0xFF16182B);
  static const Color lightTextSecondary = Color(0xFF6B7089);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0F1120);
  static const Color darkSurface = Color(0xFF191B2E);
  static const Color darkBorder = Color(0xFF2A2D45);
  static const Color darkTextPrimary = Color(0xFFF3F4FA);
  static const Color darkTextSecondary = Color(0xFF9A9DBD);

  // Habit category accent palette (used for icon backgrounds, chart bars, etc.)
  static const List<Color> categoryPalette = [
    Color(0xFF5B6CFF),
    Color(0xFF22C7B5),
    Color(0xFFFFAB2E),
    Color(0xFFEF6AAE),
    Color(0xFF32D583),
    Color(0xFF4C9EFF),
    Color(0xFFB07CF0),
    Color(0xFFFF7A59),
  ];

  static Color colorForIndex(int index) =>
      categoryPalette[index % categoryPalette.length];
}
