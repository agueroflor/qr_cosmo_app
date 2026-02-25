import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/core/usecases/usecase.dart';
import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';


class GetGuestByQrCodeUseCase implements UseCase<GuestModel?, GetGuestByQrCodeParams> {
  final GuestRepository _guestRepository;

  GetGuestByQrCodeUseCase(this._guestRepository);

  @override
  Future<Either<Failure, GuestModel?>> call(GetGuestByQrCodeParams params) async {
    return await _guestRepository.getByQrCode(params.qrCode);
  }
}

class GetGuestByQrCodeParams extends Equatable {
  final String qrCode;

  const GetGuestByQrCodeParams({required this.qrCode});

  @override
  List<Object?> get props => [qrCode];
}
