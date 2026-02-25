import 'package:flutter/material.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';
import 'package:qr_cosmo_app/presentation/theme/app_spacing.dart';
import 'package:qr_cosmo_app/presentation/theme/app_text_styles.dart';
import 'package:qr_cosmo_app/presentation/theme/app_button_styles.dart';

/// Centralized dialog helper.
///
/// Replaces 5+ hardcoded AlertDialog patterns with a consistent API.
/// All dialogs share the same shape, colors, and layout structure.
abstract final class AppDialog {
  static const double _borderRadius = 20;

  /// Confirmation dialog with cancel + confirm actions.
  ///
  /// Used for destructive actions (delete, logout, etc).
  /// [confirmLabel] defaults to 'Confirmar'.
  /// [isDanger] makes the confirm button red instead of primary.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDanger = false,
    Widget? content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        title: Text(title, style: AppTextStyles.dialogTitle),
        content: content ??
            Text(message, style: AppTextStyles.dialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              cancelLabel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: isDanger
                ? AppButtonStyles.danger()
                : AppButtonStyles.primary(),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Success feedback dialog with icon, title, and optional subtitle.
  ///
  /// Single action button that dismisses.
  static Future<void> success(
    BuildContext context, {
    required String title,
    String? subtitle,
    String buttonLabel = 'Aceptar',
    VoidCallback? onDismiss,
    Widget? extraContent,
  }) async {
    await _feedbackDialog(
      context,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      title: title,
      subtitle: subtitle,
      buttonLabel: buttonLabel,
      onDismiss: onDismiss,
      extraContent: extraContent,
    );
  }

  /// Error feedback dialog with icon, title, and message.
  ///
  /// Single action button that dismisses.
  static Future<void> error(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Aceptar',
    VoidCallback? onDismiss,
  }) async {
    await _feedbackDialog(
      context,
      icon: Icons.cancel_rounded,
      iconColor: AppColors.error,
      title: title,
      subtitle: message,
      buttonLabel: buttonLabel,
      onDismiss: onDismiss,
    );
  }

  static Future<void> _feedbackDialog(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required String buttonLabel,
    VoidCallback? onDismiss,
    Widget? extraContent,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.surface,
        contentPadding: AppSpacing.dialogContent,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: iconColor),
            ),
            AppSpacing.verticalLg,
            // Title
            Text(
              title,
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              AppSpacing.verticalSm,
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.dialogBody,
              ),
            ],
            if (extraContent != null) ...[
              AppSpacing.verticalMd,
              extraContent,
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onDismiss?.call();
              },
              style: AppButtonStyles.primary(),
              child: Text(buttonLabel, style: AppTextStyles.button),
            ),
          ),
        ],
        actionsPadding: AppSpacing.dialogActions,
      ),
    );
  }
}
