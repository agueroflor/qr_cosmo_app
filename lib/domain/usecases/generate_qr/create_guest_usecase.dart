import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/core/usecases/usecase.dart';
import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

class CreateGuestUseCase implements UseCase<String, CreateGuestParams> {
  final GuestRepository _guestRepository;

  CreateGuestUseCase(this._guestRepository);

  @override
  Future<Either<Failure, String>> call(CreateGuestParams params) async {
    return await _guestRepository.create(params.guest);
  }
}

class CreateGuestParams extends Equatable {
  final GuestModel guest;

  const CreateGuestParams({required this.guest});

  @override
  List<Object?> get props => [guest.id, guest.dni, guest.qrCode];
}
