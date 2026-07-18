import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors (Blue tone from HTML)
  static const Color primary = Color(0xFF005BBF); // Deep Blue
  static const Color primaryLight = Color(0xFFADC7FF); // inverse-primary
  static const Color primaryDark = Color(
    0xFF004493,
  ); // on-primary-fixed-variant

  static const Color secondary = Color(0xFF795900); // Yellow/Gold tone
  static const Color secondaryFixed = Color(0xFFFFDFA0);
  static const Color onSecondaryFixed = Color(0xFF261A00);

  // Background & Surface
  static const Color background = Color(0xFFF8F9FA); // Light Grayish Blue
  static const Color surface = Colors.white; // surface-container-lowest
  static const Color surfaceBright = Color(0xFFF8F9FA);
  static const Color error = Color(0xFFBA1A1A); // Red

  // Text & Outline Colors
  static const Color textPrimary = Color(0xFF191C1D); // on-surface
  static const Color textSecondary = Color(0xFF414754); // on-surface-variant
  static const Color outline = Color(0xFF727785);
  static const Color outlineVariant = Color(0xFFC1C6D6);
}
