// lib/presentation/utils/responsive_utils.dart
import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Obtener tamaño de pantalla
  static Size screenSize(BuildContext context) => MediaQuery.of(context).size;
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  
  // Padding responsive basado en ancho de pantalla
  static double responsivePadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) return 12.0; // Pantallas muy pequeñas
    if (width < 600) return 16.0; // Móviles
    if (width < 900) return 24.0; // Tablets
    return 32.0; // Pantallas grandes
  }
  
  // Espaciado vertical responsive
  static double responsiveSpacing(BuildContext context, {double small = 8.0, double medium = 12.0, double large = 16.0}) {
    final height = screenHeight(context);
    if (height < 600) return small;
    if (height < 800) return medium;
    return large;
  }
  
  // Tamaño de fuente responsive
  static double responsiveFontSize(BuildContext context, {double base = 14.0, double scale = 1.0}) {
    final width = screenWidth(context);
    final baseSize = base * scale;
    
    // Asegurar mínimo de 14px
    if (baseSize < 14.0) return 14.0;
    
    // Escalar según ancho de pantalla
    if (width < 360) return baseSize * 0.9; // Pantallas muy pequeñas
    if (width < 600) return baseSize; // Móviles
    if (width < 900) return baseSize * 1.1; // Tablets
    return baseSize * 1.2; // Pantallas grandes
  }
  
  // Tamaño de icono responsive
  static double responsiveIconSize(BuildContext context, {double base = 24.0}) {
    final width = screenWidth(context);
    if (width < 360) return base * 0.85;
    if (width < 600) return base;
    if (width < 900) return base * 1.15;
    return base * 1.3;
  }
  
  // Touch target mínimo (44x44 según Material Design)
  static double minTouchTarget = 44.0;
  
  // Botón responsive con touch target mínimo
  static double buttonHeight(BuildContext context, {double base = 48.0}) {
    final height = screenHeight(context);
    if (height < 600) return base * 0.9;
    return base;
  }
  
  // Border radius responsive
  static double responsiveRadius(BuildContext context, {double base = 12.0}) {
    final width = screenWidth(context);
    if (width < 360) return base * 0.8;
    if (width < 600) return base;
    return base * 1.2;
  }
  
  // Ancho máximo para contenido (legibilidad)
  static double maxContentWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width < 600) return width;
    return 600.0; // Máximo para legibilidad en tablets/desktop
  }
  
  // Padding simétrico responsive
  static EdgeInsets symmetricPadding(BuildContext context, {double horizontal = 16.0, double vertical = 16.0}) {
    return EdgeInsets.symmetric(
      horizontal: responsivePadding(context) * (horizontal / 16.0),
      vertical: responsiveSpacing(context, small: vertical * 0.75, medium: vertical, large: vertical * 1.25),
    );
  }
  
  // Padding all responsive
  static EdgeInsets allPadding(BuildContext context, {double base = 16.0}) {
    return EdgeInsets.all(responsivePadding(context) * (base / 16.0));
  }
  
  // SizedBox height responsive
  static SizedBox verticalSpacing(BuildContext context, {double small = 8.0, double medium = 12.0, double large = 16.0}) {
    return SizedBox(height: responsiveSpacing(context, small: small, medium: medium, large: large));
  }
  
  // SizedBox width responsive
  static SizedBox horizontalSpacing(BuildContext context, {double small = 8.0, double medium = 12.0, double large = 16.0}) {
    final width = screenWidth(context);
    double spacing;
    if (width < 360) {spacing = small;}
    else if (width < 600) {spacing = medium;}
    else {spacing = large;}
    return SizedBox(width: spacing);
  }
  
  // Determinar si es tablet o desktop
  static bool isTablet(BuildContext context) => screenWidth(context) >= 600;
  static bool isDesktop(BuildContext context) => screenWidth(context) >= 900;
  static bool isMobile(BuildContext context) => screenWidth(context) < 600;
}
