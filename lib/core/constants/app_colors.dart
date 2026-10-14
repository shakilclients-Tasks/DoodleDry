import 'package:flutter/material.dart';

/// Curated health-tech color palette for DOODLEDRY.
/// Provides high contrast, accessible, calming tones suited for infant safety and healthcare IoT.
class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryLight = Color(0xFF14B8A6); // Teal 500
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryContainer = Color(0xFFCCFBF1); // Teal 100
  static const Color onPrimaryContainer = Color(0xFF115E59);

  static const Color secondary = Color(0xFF3B82F6); // Blue 500
  static const Color secondaryLight = Color(0xFF60A5FA);
  static const Color secondaryDark = Color(0xFF1D4ED8);
  static const Color secondaryContainer = Color(0xFFDBEAFE);

  // Vitals Semantic Colors
  static const Color heartRate = Color(0xFFF43F5E); // Rose / Soft Coral
  static const Color heartRateBg = Color(0xFFFFE4E6);
  
  static const Color spo2 = Color(0xFF0284C7); // Sky Blue
  static const Color spo2Bg = Color(0xFFE0F2FE);
  
  static const Color temperature = Color(0xFFF59E0B); // Amber / Warm Orange
  static const Color temperatureBg = Color(0xFFFEF3C7);
  
  static const Color motion = Color(0xFF8B5CF6); // Violet
  static const Color motionBg = Color(0xFFEDE9FE);

  static const Color batteryGood = Color(0xFF10B981); // Emerald
  static const Color batteryLow = Color(0xFFF59E0B);
  static const Color batteryCritical = Color(0xFFEF4444);

  // Status & Alerts
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFDBEAFE);

  // Simulation Banner Color
  static const Color simulationBadge = Color(0xFF6366F1); // Indigo
  static const Color simulationBadgeBg = Color(0xFFEEF2FF);

  // Neutral Light Theme
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color dividerLight = Color(0xFFF1F5F9);

  // Neutral Dark Theme
  static const Color backgroundDark = Color(0xFF0B1120); // Deep Navy Slate
  static const Color surfaceDark = Color(0xFF151E32);
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF1E293B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF151E32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
