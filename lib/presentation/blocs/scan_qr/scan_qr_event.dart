part of 'scan_qr_bloc.dart';

/// Evento base sellado para el Bloc de escaneo QR
sealed class ScanQrEvent {
  const ScanQrEvent();
}

/// Evento: se detectó un código QR
class QrCodeDetected extends ScanQrEvent {
  final String qrCode;

  const QrCodeDetected(this.qrCode);
}

/// Evento: el usuario cambió la cantidad de invitados
class GuestCountChanged extends ScanQrEvent {
  final int count;

  const GuestCountChanged(this.count);
}

/// Evento: el usuario incrementó la cantidad
class GuestCountIncremented extends ScanQrEvent {
  const GuestCountIncremented();
}

/// Evento: el usuario decrementó la cantidad
class GuestCountDecremented extends ScanQrEvent {
  const GuestCountDecremented();
}

/// Evento: el usuario confirmó la entrada de invitados
class ConfirmGuestEntry extends ScanQrEvent {
  const ConfirmGuestEntry();
}

/// Evento: el usuario quiere escanear otro QR
class ScanAgainRequested extends ScanQrEvent {
  const ScanAgainRequested();
}

/// Evento: el usuario aceptó el diálogo de éxito
class SuccessDialogAccepted extends ScanQrEvent {
  const SuccessDialogAccepted();
}

/// Evento: el usuario aceptó el diálogo de error
class ErrorDialogAccepted extends ScanQrEvent {
  const ErrorDialogAccepted();
}
