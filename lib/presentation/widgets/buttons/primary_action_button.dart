import 'package:flutter/material.dart';

import 'package:qr_cosmo_app/presentation/theme/theme.dart';

/// Full-width primary action button with loading state.
///
/// Matches the existing pattern used in login, register, and generate screens:
/// height 56, spinner 24x24, strokeWidth 2.5.
class PrimaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final ButtonStyle? style;
  final Widget? icon;

  const PrimaryActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.style,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = (style ?? AppButtonStyles.primary()).copyWith(
      elevation: const WidgetStatePropertyAll(0),
    );

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: icon != null
          ? ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : icon!,
              label: Text(
                isLoading ? 'Cargando...' : label,
                style: AppTextStyles.button,
              ),
              style: buttonStyle,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(label, style: AppTextStyles.button),
            ),
    );
  }
}
