import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/core/usecases/usecase.dart';
import 'package:qr_cosmo_app/domain/entities/user_role.dart';
import 'package:qr_cosmo_app/domain/repositories/admin_auth_repository.dart';

class ValidateAdminAccessUseCase
    implements UseCase<UserRole, ValidateAdminAccessParams> {
  final AdminAuthRepository _adminAuthRepository;

  ValidateAdminAccessUseCase(this._adminAuthRepository);

  @override
  Future<Either<Failure, UserRole>> call(
      ValidateAdminAccessParams params) async {
    // Validación local mínima (no es lógica de negocio sensible)
    if (!params.requestedRole.requiresAdminValidation) {
      return Right(params.requestedRole);
    }

    if (params.accessCode.isEmpty) {
      return const Left(AuthFailure(
        'Se requiere código de acceso para este rol',
        code: 'ADMIN_PASSWORD_REQUIRED',
      ));
    }

    return _adminAuthRepository.validateAdminAccess(
      accessCode: params.accessCode,
      requestedRole: params.requestedRole,
    );
  }
}

/// Parámetros para ValidateAdminAccessUseCase
class ValidateAdminAccessParams extends Equatable {
  final String accessCode;
  final UserRole requestedRole;

  const ValidateAdminAccessParams({
    required this.accessCode,
    required this.requestedRole,
  });

  @override
  List<Object?> get props => [accessCode, requestedRole];
}
