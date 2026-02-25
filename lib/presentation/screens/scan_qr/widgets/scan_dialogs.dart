// lib/screens/scan_qr/widgets/scan_dialogs.dart
// Funciones para mostrar diálogos de éxito y error
// Contienen la UI pero reciben callbacks para la navegación
// NO contienen lógica de negocio - reciben datos ya procesados

import 'package:flutter/material.dart';
import 'package:qr_cosmo_app/presentation/theme/app_button_styles.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';
import 'package:qr_cosmo_app/presentation/theme/app_text_styles.dart';

/// Datos del invitado para mostrar en el diálogo de éxito
/// Evita pasar el modelo completo al widget
class GuestDisplayData {
  final String name;
  final String accessTypeLabel;

  const GuestDisplayData({
    required this.name,
    required this.accessTypeLabel,
  });
}

/// Muestra el diálogo de éxito con información del invitado
/// [onAccept] se llama cuando el usuario presiona Aceptar
/// [guestData] contiene datos ya procesados para mostrar (sin lógica de negocio)
Future<void> showScanSuccessDialog({
  required BuildContext context,
  required VoidCallback onAccept,
  GuestDisplayData? guestData,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.surface,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de éxito
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 20),
            // Título
            const Text(
              'Acceso confirmado',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 8),
            // Subtítulo
            const Text(
              'La entrada fue validada correctamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            // Info del invitado para QR personal
            if (guestData != null) ...[
              const SizedBox(height: 16),
              _GuestInfoBox(
                guestName: guestData.name,
                accessTypeLabel: guestData.accessTypeLabel,
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onAccept();
              },
              style: AppButtonStyles.primary(),
              child: const Text(
                'Aceptar',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      );
    },
  );
}

/// Muestra el diálogo de error
/// [onAccept] se llama cuando el usuario presiona Aceptar
Future<void> showScanErrorDialog({
  required BuildContext context,
  required String message,
  required VoidCallback onAccept,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.surface,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de error
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_rounded,
                size: 56,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            // Título
            const Text(
              'Acceso denegado',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 12),
            // Mensaje
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onAccept();
              },
              style: AppButtonStyles.primary(),
              child: const Text(
                'Aceptar',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      );
    },
  );
}

/// Widget interno para mostrar la info del invitado en el diálogo de éxito
class _GuestInfoBox extends StatelessWidget {
  final String guestName;
  final String accessTypeLabel;

  const _GuestInfoBox({
    required this.guestName,
    required this.accessTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre
          Text(
            guestName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Tipo de acceso
          Row(
            children: [
              const Icon(
                Icons.badge_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                accessTypeLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Estado
          const Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 14,
                color: AppColors.success,
              ),
              SizedBox(width: 6),
              Text(
                'Acceso válido',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
