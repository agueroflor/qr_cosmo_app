import 'package:flutter/material.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

/// Centralized SnackBar helper.
///
/// Replaces 18+ inline ScaffoldMessenger.showSnackBar calls with
/// consistent color and duration across the entire app.
abstract final class AppSnackbar {
  static const Duration _defaultDuration = Duration(seconds: 3);

  /// Show a success SnackBar (green background).
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.success);
  }

  /// Show an error SnackBar (red background).
  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.error);
  }

  /// Show an info SnackBar (blue background).
  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.info);
  }

  static void _show(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: _defaultDuration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
  }
}
