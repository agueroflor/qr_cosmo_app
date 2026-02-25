// lib/screens/scan_qr/widgets/scan_action_buttons.dart
// Widgets puros para los botones de acción del scanner
// NO contienen lógica de negocio - solo reciben callbacks por constructor

import 'package:flutter/material.dart';
import 'package:qr_cosmo_app/presentation/theme/app_button_styles.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

/// Botón primario de confirmar entrada
class ConfirmEntryButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback? onPressed;

  const ConfirmEntryButton({
    super.key,
    required this.isProcessing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isProcessing ? null : onPressed,
        style: AppButtonStyles.success().copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.success.withValues(alpha: 0.4);
            }
            return AppColors.success;
          }),
        ),
        child: isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Confirmar Entrada',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Botón secundario de cancelar
class CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CancelButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: AppButtonStyles.outlined().copyWith(
          foregroundColor: const WidgetStatePropertyAll(AppColors.textSecondary),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.textSecondary)),
        ),
        child: const Text(
          'Cancelar',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
