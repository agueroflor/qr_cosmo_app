import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/core/usecases/usecase.dart';
import 'package:qr_cosmo_app/core/services/qr_service.dart';

class GenerateQrCodeUseCase implements UseCase<String, GenerateQrCodeParams> {
  GenerateQrCodeUseCase();

  @override
  Future<Either<Failure, String>> call(GenerateQrCodeParams params) async {
    try {
      final qrCode = QRService.generateQRCode(
        guestId: params.guestId,
        dni: params.dni,
        createdAt: params.createdAt,
      );
      return Right(qrCode);
    } catch (e, stackTrace) {
      return Left(UnexpectedFailure(
        'Error generando código QR',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}

class GenerateQrCodeParams extends Equatable {
  final String guestId;
  final String dni;
  final DateTime createdAt;

  const GenerateQrCodeParams({
    required this.guestId,
    required this.dni,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [guestId, dni, createdAt];
}
