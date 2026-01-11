// import 'package:flutter/material.dart';

// class AppColors {
//   static const Color primary = Color(0xFF2563EB);
//   static const Color secondary = Color(0xFF10B981);
//   static const Color error = Color(0xFFEF4444);
//   static const Color warning = Color(0xFFF59E0B);
//   static const Color success = Color(0xFF10B981);
  
//   static const Color background = Color(0xFFF9FAFB);
//   static const Color surface = Colors.white;
//   static const Color textPrimary = Color(0xFF1F2937);
//   static const Color textSecondary = Color(0xFF6B7280);
// }

import 'package:flutter/material.dart';

class AppColors {
  // Primary color with shades
  static const MaterialColor primary = MaterialColor(
    0xFF2563EB,
    <int, Color>{
      50: Color(0xFFEFF6FF),
      100: Color(0xFFDBEAFE),
      200: Color(0xFFBFDBFE),
      300: Color(0xFF93C5FD),
      400: Color(0xFF60A5FA),
      500: Color(0xFF2563EB), // Your main color
      600: Color(0xFF1D4ED8),
      700: Color(0xFF1E40AF),
      800: Color(0xFF1E3A8A),
      900: Color(0xFF1E3A8A),
    },
  );

  // Secondary color with shades
  static const MaterialColor secondary = MaterialColor(
    0xFF10B981,
    <int, Color>{
      50: Color(0xFFECFDF5),
      100: Color(0xFFD1FAE5),
      200: Color(0xFFA7F3D0),
      300: Color(0xFF6EE7B7),
      400: Color(0xFF34D399),
      500: Color(0xFF10B981), // Your main color
      600: Color(0xFF059669),
      700: Color(0xFF047857),
      800: Color(0xFF065F46),
      900: Color(0xFF064E3B),
    },
  );

  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
}