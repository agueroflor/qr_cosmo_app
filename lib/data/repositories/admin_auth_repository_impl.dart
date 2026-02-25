// lib/data/repositories/admin_auth_repository_impl.dart
// Implementación temporal del repositorio de validación administrativa.
//
// ╔══════════════════════════════════════════════════════════════════╗
// ║  PLACEHOLDER - REEMPLAZAR CON IMPLEMENTACIÓN BACKEND           ║
// ║                                                                 ║
// ║  Esta implementación es un stub temporal que permite el flujo   ║
// ║  de registro sin validar credenciales reales.                   ║
// ║                                                                 ║
// ║  Para producción, reemplazar con:                               ║
// ║  - Firebase Functions (Cloud Functions callable)                ║
// ║  - Firebase Custom Claims (setCustomUserClaims)                 ║
// ║  - API REST con validación server-side                          ║
// ║                                                                 ║
// ║  La interfaz AdminAuthRepository no cambia.                     ║
// ║  Solo se reemplaza esta clase en el DI (getIt).                 ║
// ╚══════════════════════════════════════════════════════════════════╝

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/entities/user_role.dart';
import 'package:qr_cosmo_app/domain/repositories/admin_auth_repository.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  @override
  Future<Either<Failure, UserRole>> validateAdminAccess({
    required String accessCode,
    required UserRole requestedRole,
  }) async {
    // Simular latencia de red para que el flujo se comporte
    // como lo hará con un backend real.
    await Future.delayed(const Duration(milliseconds: 300));

    debugPrint(
      '[AdminAuthRepository] STUB: Validación simulada para rol ${requestedRole.name}. '
      'Reemplazar con implementación backend.',
    );

    // Aceptar cualquier código no vacío.
    // La validación real de credenciales NUNCA debe vivir en el cliente.
    if (accessCode.trim().isEmpty) {
      return const Left(AuthFailure(
        'Código de acceso inválido',
        code: 'INVALID_ADMIN_PASSWORD',
      ));
    }

    return Right(requestedRole);
  }
}
