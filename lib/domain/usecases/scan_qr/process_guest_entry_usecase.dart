import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/core/usecases/usecase.dart';
import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/domain/repositories/visit_repository.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/validate_invitation_validity_usecase.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import 'package:qr_cosmo_app/data/models/visit_model.dart';

class ProcessGuestEntryUseCase implements UseCase<void, ProcessGuestEntryParams> {
  final GuestRepository _guestRepository;
  final VisitRepository _visitRepository;
  final ValidateInvitationValidityUseCase _validateInvitationValidity;

  ProcessGuestEntryUseCase(
    this._guestRepository,
    this._visitRepository,
    this._validateInvitationValidity,
  );

  @override
  Future<Either<Failure, void>> call(ProcessGuestEntryParams params) async {
    try {
      final guest = params.guest;
      final count = params.count;
      final scannerId = params.scannerId;
      final scannerName = params.scannerName;

      // Validar que el guest esté activo
      if (!guest.isActive) {
        return Left(QrFailure.deactivated());
      }

      // Validar invitación si aplica (estado, usos, y vigencia)
      if (guest.isInvitation) {
        final validityResult = await _validateInvitationValidity(
          ValidateInvitationValidityParams(
            guest: guest,
            currentDateTime: DateTime.now(),
          ),
        );
        if (validityResult.isLeft()) {
          return validityResult;
        }
      }

      // Determinar si es primera visita
      final isFirstTime = guest.totalVisits == 0;

      // Crear las visitas según el count
      final List<VisitModel> visits = [];
      final now = DateTime.now();

      for (int i = 0; i < count; i++) {
        visits.add(VisitModel(
          id: '', // Se generará en Firestore
          guestId: guest.id,
          guestName: guest.name,
          dni: guest.dni,
          scannedBy: scannerId,
          scannedByName: scannerName,
          scannedAt: now,
          isFirstTime: isFirstTime && i == 0, // Solo la primera visita es "primera vez"
        ));
      }

      // Crear visitas en batch si son múltiples, o una sola si es count=1
      if (visits.length == 1) {
        final visitResult = await _visitRepository.create(visits.first);
        if (visitResult.isLeft()) {
          return Left(visitResult.fold(
            (failure) => failure,
            (_) => const UnexpectedFailure('Error inesperado'),
          ));
        }
      } else {
        final batchResult = await _visitRepository.createBatch(visits);
        if (batchResult.isLeft()) {
          return Left(batchResult.fold(
            (failure) => failure,
            (_) => const UnexpectedFailure('Error inesperado'),
          ));
        }
      }

      // Actualizar contador de visitas del guest
      final updateResult = await _guestRepository.markAsUsed(guest.id, count: count);
      if (updateResult.isLeft()) {
        return Left(updateResult.fold(
          (failure) => failure,
          (_) => const UnexpectedFailure('Error inesperado'),
        ));
      }

      return const Right(null);
    } catch (e, stackTrace) {
      return Left(UnexpectedFailure(
        'Error procesando entrada',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}

class ProcessGuestEntryParams extends Equatable {
  final GuestModel guest;
  final int count;
  final String scannerId;
  final String scannerName;

  const ProcessGuestEntryParams({
    required this.guest,
    this.count = 1,
    required this.scannerId,
    required this.scannerName,
  });

  @override
  List<Object?> get props => [guest.id, count, scannerId, scannerName];
}
