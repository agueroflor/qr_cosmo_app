import 'package:dartz/dartz.dart';

import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';

abstract class AdminAuthRepository {
  /// Valida las credenciales de acceso para un rol privilegiado.
  ///
  /// Retorna el [UserRole] asignado si la validación es exitosa.
  /// Retorna un [Failure] si las credenciales son inválidas o si
  /// ocurre un error de red/servicio.
  ///
  /// [accessCode] es la credencial proporcionada por el usuario.
  /// [requestedRole] es el rol solicitado.
  Future<Either<Failure, UserRole>> validateAdminAccess({
    required String accessCode,
    required UserRole requestedRole,
  });
}
