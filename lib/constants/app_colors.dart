import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Turquoise (Firoozei)
  static const Color primary = Color(0xFF1ABC9C); // Turquoise
  static const Color primaryColor = Color(0xFF1ABC9C);
  
  // Secondary Colors - Navy Blue (Sormei)
  static const Color secondaryColor = Color(0xFF1E3A8A); // Navy Blue
  
  // Accent Colors - Lighter Turquoise variations
  static const Color lightTurquoise = Color(0xFF4ECDC4); // Light Turquoise
  static const Color darkTurquoise = Color(0xFF16A085); // Dark Turquoise
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6C757D);
  static const Color darkGray = Color(0xFF495057);

  // Material Color
  static MaterialColor kMaterialPrimaryColor = const MaterialColor(
    0xFF1ABC9C,
    <int, Color>{
      50: Color(0xFFE8F8F5),
      100: Color(0xFFD1F2EB),
      200: Color(0xFFA3E4D7),
      300: Color(0xFF76D7C4),
      400: Color(0xFF48C9B0),
      500: Color(0xFF1ABC9C), // Primary
      600: Color(0xFF17A2B8),
      700: Color(0xFF16A085),
      800: Color(0xFF138D75),
      900: Color(0xFF117A65),
    },
  );
}

