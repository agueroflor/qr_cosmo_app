import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/core/usecases/usecase.dart';
import 'package:qr_cosmo_app/core/services/qr_service.dart';

class ValidateQrCodeUseCase implements UseCase<bool, ValidateQrCodeParams> {
  ValidateQrCodeUseCase();

  @override
  Future<Either<Failure, bool>> call(ValidateQrCodeParams params) async {
    try {
      final isValid = QRService.isValidQRCode(params.qrCode);
      return Right(isValid);
    } catch (e, stackTrace) {
      return Left(UnexpectedFailure(
        'Error validando código QR',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}

class ValidateQrCodeParams extends Equatable {
  final String qrCode;

  const ValidateQrCodeParams({required this.qrCode});

  @override
  List<Object?> get props => [qrCode];
}
