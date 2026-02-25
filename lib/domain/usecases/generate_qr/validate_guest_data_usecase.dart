import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/core/usecases/usecase.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

class ValidateGuestDataUseCase implements UseCase<List<String>, ValidateGuestDataParams> {
  ValidateGuestDataUseCase();

  @override
  Future<Either<Failure, List<String>>> call(ValidateGuestDataParams params) async {
    try {
      final errors = <String>[];
      final guest = params.guest;

      // Validar nombre
      if (guest.name.trim().isEmpty) {
        errors.add('El nombre es requerido');
      } else if (guest.name.trim().length < 2) {
        errors.add('El nombre debe tener al menos 2 caracteres');
      } else if (guest.name.trim().length > 100) {
        errors.add('El nombre no puede tener más de 100 caracteres');
      }

      // Validar DNI
      if (guest.dni.trim().isEmpty) {
        errors.add('El DNI es requerido');
      } else if (!_isValidDni(guest.dni.trim())) {
        errors.add('El DNI debe tener entre 7 y 8 dígitos numéricos');
      }

      // Validar creador
      if (guest.createdBy.trim().isEmpty) {
        errors.add('El ID del creador es requerido');
      }

      if (guest.createdByName.trim().isEmpty) {
        errors.add('El nombre del creador es requerido');
      }

      // Validaciones para invitaciones
      if (guest.isInvitation) {
        if (guest.maxUses != null && guest.maxUses! < 1) {
          errors.add('El número máximo de usos debe ser al menos 1');
        }

        if (guest.validUntil != null) {
          final today = DateTime.now();
          final validDate = guest.validUntil!;
          // Comparar solo fechas, no hora (por horarios nocturnos)
          final todayDate = DateTime(today.year, today.month, today.day);
          final validDateOnly = DateTime(validDate.year, validDate.month, validDate.day);

          if (validDateOnly.isBefore(todayDate)) {
            errors.add('La fecha de validez no puede ser anterior a hoy');
          }
        }
      }

      return Right(errors);
    } catch (e, stackTrace) {
      return Left(UnexpectedFailure(
        'Error validando datos del invitado',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Valida si el DNI tiene formato correcto (7-8 dígitos)
  bool _isValidDni(String dni) {
    // Remover puntos si los tiene
    final cleanDni = dni.replaceAll('.', '');
    // Validar que tenga 7 u 8 dígitos
    final regex = RegExp(r'^\d{7,8}$');
    return regex.hasMatch(cleanDni);
  }
}

class ValidateGuestDataParams extends Equatable {
  final GuestModel guest;

  const ValidateGuestDataParams({required this.guest});

  @override
  List<Object?> get props => [guest.id, guest.name, guest.dni];
}
