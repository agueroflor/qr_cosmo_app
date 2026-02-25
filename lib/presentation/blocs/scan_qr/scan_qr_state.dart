part of 'scan_qr_bloc.dart';

/// Estado base sellado para el Bloc de escaneo QR
sealed class ScanQrState {
  const ScanQrState();
}

/// Estado inicial: esperando escaneo
class ScanQrIdle extends ScanQrState {
  const ScanQrIdle();
}

/// Estado: procesando código QR
class ScanQrProcessing extends ScanQrState {
  const ScanQrProcessing();
}

/// Estado: escaneo exitoso
class ScanQrSuccess extends ScanQrState {
  final String guestName;
  final String accessTypeLabel;

  const ScanQrSuccess({
    required this.guestName,
    required this.accessTypeLabel,
  });
}

/// Estado: error en el escaneo
class ScanQrError extends ScanQrState {
  final String message;
  final ScanErrorType errorType;

  const ScanQrError({
    required this.message,
    required this.errorType,
  });
}

/// Tipos de errores posibles en el escaneo
enum ScanErrorType {
  noConnection,
  invalidQr,
  qrNotFound,
  qrDeactivated,
  qrUsedToday,
  maxUsesReached,
  invitationExpired,
  invalidOperationalDay,
  notForToday,
  noActiveOperationalDay,
  generic,
}

/// Estado: invitación grupal - requiere seleccionar cantidad
class ScanQrInvitationInput extends ScanQrState {
  final String guestName;
  final String? validUntilFormatted;
  final String createdByName;
  final int maxUses;
  final int remainingUses;
  final String? lastUsedDateFormatted;
  final Color remainingUsesColor;
  final int guestCount;
  final bool isConfirming;
  final String guestId;
  final bool wasUsedRecently;
  final int lastScanCount;
  final String? validityDescription;

  const ScanQrInvitationInput({
    required this.guestName,
    required this.validUntilFormatted,
    required this.createdByName,
    required this.maxUses,
    required this.remainingUses,
    required this.lastUsedDateFormatted,
    required this.remainingUsesColor,
    required this.guestCount,
    required this.isConfirming,
    required this.guestId,
    required this.wasUsedRecently,
    required this.lastScanCount,
    this.validityDescription,
  });

  ScanQrInvitationInput copyWith({
    String? guestName,
    String? validUntilFormatted,
    String? createdByName,
    int? maxUses,
    int? remainingUses,
    String? lastUsedDateFormatted,
    Color? remainingUsesColor,
    int? guestCount,
    bool? isConfirming,
    String? guestId,
    bool? wasUsedRecently,
    int? lastScanCount,
    String? validityDescription,
  }) {
    return ScanQrInvitationInput(
      guestName: guestName ?? this.guestName,
      validUntilFormatted: validUntilFormatted ?? this.validUntilFormatted,
      createdByName: createdByName ?? this.createdByName,
      maxUses: maxUses ?? this.maxUses,
      remainingUses: remainingUses ?? this.remainingUses,
      lastUsedDateFormatted: lastUsedDateFormatted ?? this.lastUsedDateFormatted,
      remainingUsesColor: remainingUsesColor ?? this.remainingUsesColor,
      guestCount: guestCount ?? this.guestCount,
      isConfirming: isConfirming ?? this.isConfirming,
      guestId: guestId ?? this.guestId,
      wasUsedRecently: wasUsedRecently ?? this.wasUsedRecently,
      lastScanCount: lastScanCount ?? this.lastScanCount,
      validityDescription: validityDescription ?? this.validityDescription,
    );
  }
}

/// Mensaje de validación (snackbar)
class ScanQrValidationMessage {
  final String message;
  final ValidationMessageType type;

  const ScanQrValidationMessage({
    required this.message,
    required this.type,
  });
}

enum ValidationMessageType {
  error,
  warning,
}
