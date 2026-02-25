import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/core/usecases/usecase.dart';
import 'package:qr_cosmo_app/domain/entities/invitation_validity_type.dart';
import 'package:qr_cosmo_app/domain/entities/operational_day.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

class ValidateInvitationValidityUseCase
    implements UseCase<void, ValidateInvitationValidityParams> {
  @override
  Future<Either<Failure, void>> call(
    ValidateInvitationValidityParams params,
  ) async {
    final guest = params.guest;
    final now = params.currentDateTime;

    // Solo validar invitaciones
    if (!guest.isInvitation) {
      return const Right(null);
    }

    // Validar estado activo
    if (!guest.isActive) {
      return Left(QrFailure.deactivated());
    }

    // Validar usos restantes
    if (!guest.hasRemainingUses) {
      return Left(QrFailure.maxUsesReached(guest.maxUses ?? 0));
    }

    // Validar según tipo de validez
    switch (guest.validityType) {
      case InvitationValidityType.unlimited:
        return const Right(null);

      case InvitationValidityType.expirationDate:
        if (guest.validForDate == null) {
          return const Right(null);
        }
        if (now.isAfter(guest.validForDate!)) {
          return Left(QrFailure.invitationExpired());
        }
        return const Right(null);

      case InvitationValidityType.operationalDay:
        if (guest.validForDate == null) {
          return const Right(null);
        }

        final currentOp = getOperationalDay(now);
        if (currentOp == null) {
          return Left(QrFailure.noActiveOperationalDay());
        }

        final invitationOp = getOperationalDayFromDate(guest.validForDate!);
        if (invitationOp == null || currentOp != invitationOp) {
          return Left(QrFailure.notForToday());
        }

        return const Right(null);
    }
  }
}

class ValidateInvitationValidityParams extends Equatable {
  final GuestModel guest;
  final DateTime currentDateTime;

  const ValidateInvitationValidityParams({
    required this.guest,
    required this.currentDateTime,
  });

  @override
  List<Object?> get props => [guest.id, currentDateTime];
}
