import 'package:flutter/material.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

/// Card con información detallada de la invitación
class InvitationInfoCard extends StatelessWidget {
  final String name;
  final DateTime? validUntil;
  final String createdByName;
  final int maxUses;
  final int remainingUses;
  final DateTime? lastUsedDate;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatDateTime;
  /// Color para mostrar los usos restantes (decidido por el orquestador)
  final Color remainingUsesColor;

  const InvitationInfoCard({
    super.key,
    required this.name,
    required this.validUntil,
    required this.createdByName,
    required this.maxUses,
    required this.remainingUses,
    required this.lastUsedDate,
    required this.formatDate,
    required this.formatDateTime,
    required this.remainingUsesColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INVITACIÓN GRUPAL',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (validUntil != null)
            InvitationMetaRow(
              icon: Icons.person_outline_rounded,
              label: 'Nombre',
              value: name,
            ),
          if (validUntil != null)
            InvitationMetaRow(
              icon: Icons.event_rounded,
              label: 'Válida para',
              value: formatDate(validUntil!),
            ),
          InvitationMetaRow(
            icon: Icons.person_outline_rounded,
            label: 'Generada por',
            value: createdByName,
          ),
          InvitationMetaRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Total de usos',
            value: maxUses.toString(),
          ),
          InvitationMetaRow(
            icon: Icons.how_to_reg_rounded,
            label: 'Usos restantes',
            value: remainingUses.toString(),
            valueColor: remainingUsesColor,
            isBold: true,
          ),
          if (lastUsedDate != null)
            InvitationMetaRow(
              icon: Icons.access_time_rounded,
              label: 'Último uso',
              value: formatDateTime(lastUsedDate!),
            ),
        ],
      ),
    );
  }
}

/// Fila de metadato con icono, label y valor
class InvitationMetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const InvitationMetaRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
