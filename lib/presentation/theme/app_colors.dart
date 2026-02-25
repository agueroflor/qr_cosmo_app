import 'package:flutter/material.dart';

class AppColors {
  // Colores principales basados en el logo del bar
  static const Color primary = Color(0xFFE91E63); // Rosa fucsia principal
  static const Color primaryDark = Color(0xFFC2185B); // Rosa fucsia oscuro
  static const Color primaryLight = Color(0xFFF8BBD9); // Rosa fucsia claro
  
  // Colores secundarios del logo
  static const Color neonBlue = Color(0xFF00E5FF); // Azul neón de la copa
  static const Color neonOrange = Color(0xFFFF9800); // Naranja de la guarnición
  static const Color accentRed = Color(0xFFE91E63); // Rojo de la cereza
  
  // Colores neutros
  static const Color background = Color(0xFFF5F5F5); // Fondo claro
  static const Color surface = Colors.white; // Superficie de tarjetas
  static const Color textPrimary = Color(0xFF212121); // Texto principal
  static const Color textSecondary = Color(0xFF757575); // Texto secundario
  
  // Colores de estado
  static const Color success = Color(0xFF4CAF50); // Verde para éxito
  static const Color warning = Color(0xFFFF9800); // Naranja para advertencias
  static const Color error = Color(0xFFF44336); // Rojo para errores
  static const Color info = Color(0xFF2196F3); // Azul para información
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonBlue, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
