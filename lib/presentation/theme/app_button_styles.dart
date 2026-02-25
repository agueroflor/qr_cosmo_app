import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable button styles matching the existing codebase patterns.
///
/// Every ElevatedButton and OutlinedButton in the app uses borderRadius 12
/// and vertical padding 14. This class centralizes those into named presets.
abstract final class AppButtonStyles {
  static const double _borderRadius = 12;
  static const EdgeInsets _padding = EdgeInsets.symmetric(vertical: 14);

  /// Primary action button (pink/primary background, white text).
  static ButtonStyle primary() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: _padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      );

  /// Destructive action button (red background, white text).
  static ButtonStyle danger() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        padding: _padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      );

  /// Success action button (green background, white text).
  static ButtonStyle success() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        padding: _padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      );

  /// Secondary outlined button (grey border, no fill).
  static ButtonStyle outlined() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: _padding,
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      );
}
