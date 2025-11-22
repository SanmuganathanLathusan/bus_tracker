import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (WayGo)
  static const Color waygoDarkBlue = Color(0xFF0C2442);
  static const Color waygoLightBlue = Color(0xFF59C9F0);
  static const Color waygoPaleBackground = Color(0xFFECF6FC);
  static const Color waygoWhite = Color(0xFFFFFFFF);

  // Backgrounds
  static const Color backgroundPrimary = waygoPaleBackground;
  static const Color backgroundSecondary = waygoWhite;

  // Primary accents
  static const Color accentPrimary = waygoLightBlue;
  static const Color accentDark = waygoDarkBlue;

  // Success / Error / Warning
  static const Color accentSuccess = Color(0xFF4CAF50); // green
  static const Color accentSuccessDark = Color(0xFF2E7D32); // darker green
  static const Color accentError = Color(0xFFE63946); // red
  static const Color accentWarning = Color(0xFFFFA726); // orange
  static const Color accentWarningDark = Color(0xFFF57C00); // darker orange

  // Text colors
  static const Color textPrimary = waygoDarkBlue;
  static const Color textSecondary = Color(0xFF457B9D);
  static const Color textLight = waygoWhite;
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  // Borders / dividers
  static const Color borderLight = Color(0xFFBFD7ED);
  static const Color borderDark = Color(0xFF406882);

  // Icons
  static const Color iconPrimary = waygoDarkBlue;
  static const Color iconSecondary = waygoLightBlue;

  // Shadows
  static const Color shadowLight = Color(0x1A000000);
}
