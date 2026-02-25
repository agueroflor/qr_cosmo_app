// lib/presentation/errors/failure_message_mapper.dart
// Mapeo Failure → mensaje de UI (única fuente de verdad para mensajes de error en scan_qr)

import 'package:qr_cosmo_app/domain/errors/failures.dart';

/// Mapea un [Failure] al mensaje que debe mostrarse en la UI.
/// Usar failure.code para discriminar QrFailure.
String mapFailureToMessage(Failure failure) {
  if (failure is NetworkFailure) {
    return _msgNoConnection;
  }
  if (failure is QrFailure) {
    return _mapQrFailureToMessage(failure);
  }
  if (failure is UnexpectedFailure) {
    return _mapExceptionMessageToUserMessage(failure.message);
  }
  return failure.message;
}

String _mapQrFailureToMessage(QrFailure failure) {
  final code = failure.code;
  switch (code) {
    case 'INVALID_FORMAT':
      return _msgInvalidQr;
    case 'QR_NOT_FOUND':
      return _msgQrNotFoundInDb;
    case 'QR_DEACTIVATED':
      return _msgQrDeactivated;
    case 'ALREADY_USED_TODAY':
      return _msgQrUsedToday;
    case 'MAX_USES_REACHED':
      final match = RegExp(r'\((\d+)\)').firstMatch(failure.message);
      final n = match != null ? int.tryParse(match.group(1) ?? '0') ?? 0 : 0;
      return 'Esta invitación ya alcanzó el máximo de usos ($n).';
    case 'INVITATION_EXPIRED':
      return _msgInvitationExpired;
    case 'INVALID_OPERATIONAL_DAY':
      return _msgInvalidOperationalDay;
    case 'NOT_FOR_TODAY':
      return _msgQrNotForToday;
    case 'NO_ACTIVE_OPERATIONAL_DAY':
      return _msgNoActiveOperationalDay;
    default:
      return failure.message;
  }
}

/// Para excepciones (UnexpectedFailure): misma lógica que el antiguo mapErrorToUserMessage.
String _mapExceptionMessageToUserMessage(String errorMessage) {
  if (errorMessage.contains('no encontrado en la base de datos')) {
    return _msgQrNotFoundInDb;
  }
  if (errorMessage.contains('Sin conexión')) {
    return _msgNoConnection;
  }
  if (errorMessage.contains('inválido') || errorMessage.contains('Código QR inválido')) {
    return _msgInvalidQr;
  }
  if (errorMessage.contains('desactivado')) {
    return _msgQrDeactivated;
  }
  if (errorMessage.contains('ya fue utilizado hoy')) {
    return _msgQrUsedToday;
  }
  if (errorMessage.contains('máximo de usos')) {
    return errorMessage;
  }
  if (errorMessage.contains('ha expirado')) {
    return _msgInvitationExpired;
  }
  if (errorMessage.contains('no es válida para esta noche')) {
    return _msgInvalidOperationalDay;
  }
  if (errorMessage.contains('No hay noche operativa')) {
    return _msgNoActiveOperationalDay;
  }
  if (errorMessage.startsWith('Exception: ')) {
    return errorMessage.substring(11);
  }
  return errorMessage;
}

// ─── Textos de UI (antes en ScanErrorMessages) ───────────────────────────────

const String _msgNoConnection =
    'Sin conexión a Internet. Verificá tu conexión e intentá de nuevo.';
const String _msgInvalidQr =
    'Código QR inválido. No es un código de Cosmo.';
const String _msgQrNotFoundInDb =
    'El QR no existe en la base de datos.';
const String _msgQrDeactivated =
    'Este QR ha sido desactivado por un administrador.';
const String _msgQrUsedToday =
    'Este QR ya fue utilizado hoy. Recordá que el QR es de uso personal e intransferible.';
const String _msgInvitationExpired =
    'Esta invitación ha expirado.';
const String _msgInvalidOperationalDay =
    'Esta invitación no es válida para la noche de hoy.';
const String _msgQrNotForToday =
    'Este QR no corresponde a la noche operativa de hoy.';
const String _msgNoActiveOperationalDay =
    'No hay noche operativa activa en este momento.';

// ─── Mensajes de validación (scan_qr, sin Failure asociado) ──────────────────

/// Mensaje cuando la cantidad de invitados es < 1.
const String msgMinGuestCount = 'La cantidad debe ser al menos 1';

/// Mensaje cuando se debe escanear la misma cantidad que la última vez.
String msgSameScanCountRequired(int count) =>
    'Debe escanear la misma cantidad que la última vez ($count invitado${count != 1 ? 's' : ''}) para evitar errores.';

/// Mensaje cuando la invitación no tiene usos disponibles.
const String msgNoRemainingUses =
    'Esta invitación no tiene usos disponibles.';

/// Mensaje cuando la cantidad supera el máximo de usos.
String msgMaxGuestCount(int maxCount) =>
    'La cantidad no puede ser mayor a $maxCount (usos disponibles)';

/// Mensaje interno cuando el guest es null en confirmación.
const String msgGuestNotFoundInternal = 'Error interno: guest no encontrado';
