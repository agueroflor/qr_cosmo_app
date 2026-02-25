part of 'generate_qr_cubit.dart';

/// Estado base para el cubit de generación de QR
sealed class GenerateQrState extends Equatable {
  const GenerateQrState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - formulario listo para llenar
class GenerateQrInitial extends GenerateQrState {
  const GenerateQrInitial();
}

/// Estado de carga - generando QR
class GenerateQrLoading extends GenerateQrState {
  const GenerateQrLoading();
}

/// Estado de éxito - QR generado
class GenerateQrSuccess extends GenerateQrState {
  final GuestModel guest;
  final String qrCode;

  const GenerateQrSuccess({required this.guest, required this.qrCode});

  @override
  List<Object?> get props => [guest, qrCode];
}

/// Estado de error
class GenerateQrError extends GenerateQrState {
  final String message;

  const GenerateQrError(this.message);

  @override
  List<Object?> get props => [message];
}
