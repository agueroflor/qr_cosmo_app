import 'package:flutter/material.dart';
import 'package:qr_cosmo_app/presentation/theme/theme.dart';

AppBar appAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  bool showBackButton = true,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    leading: showBackButton
        ? IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          )
        : null,
    automaticallyImplyLeading: false,
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    actions: actions,
  );
}
