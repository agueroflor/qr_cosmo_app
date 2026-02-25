import 'package:equatable/equatable.dart';

/// Clase base para todos los errores de negocio de la aplicación
sealed class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Error de conexión a internet
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a internet'])
      : super(code: 'NETWORK_ERROR');
}

/// Recurso no encontrado
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});

  factory NotFoundFailure.entity(String entity) =>
      NotFoundFailure('$entity no encontrado', code: 'NOT_FOUND');
}

/// Error de autorización / permisos
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message, {super.code});

  factory UnauthorizedFailure.permissionDenied() =>
      const UnauthorizedFailure('Permiso denegado', code: 'PERMISSION_DENIED');
}

/// Error desconocido o inesperado
class UnknownFailure extends Failure {
  final Object? originalError;
  final StackTrace? stackTrace;

  const UnknownFailure(
    super.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, originalError];
}

/// Error de autenticación
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});

  factory AuthFailure.invalidCredentials() =>
      const AuthFailure('Credenciales inválidas', code: 'INVALID_CREDENTIALS');

  factory AuthFailure.userNotFound() =>
      const AuthFailure('Usuario no encontrado', code: 'USER_NOT_FOUND');

  factory AuthFailure.emailAlreadyInUse() =>
      const AuthFailure('El email ya está registrado', code: 'EMAIL_IN_USE');

  factory AuthFailure.weakPassword() =>
      const AuthFailure('La contraseña es muy débil', code: 'WEAK_PASSWORD');

  factory AuthFailure.sessionExpired() =>
      const AuthFailure('Sesión expirada', code: 'SESSION_EXPIRED');
}

/// Error de base de datos / Firestore
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});

  factory DatabaseFailure.notFound(String entity) =>
      DatabaseFailure('$entity no encontrado', code: 'NOT_FOUND');

  factory DatabaseFailure.permissionDenied() =>
      const DatabaseFailure('Permiso denegado', code: 'PERMISSION_DENIED');

  factory DatabaseFailure.alreadyExists(String entity) =>
      DatabaseFailure('$entity ya existe', code: 'ALREADY_EXISTS');
}

/// Error de validación
class ValidationFailure extends Failure {
  final List<String> errors;

  const ValidationFailure(super.message, {this.errors = const []});

  @override
  List<Object?> get props => [message, errors];
}

/// Error de QR
class QrFailure extends Failure {
  const QrFailure(super.message, {super.code});

  factory QrFailure.invalidFormat() =>
      const QrFailure('Código QR inválido', code: 'INVALID_FORMAT');

  factory QrFailure.notFound() =>
      const QrFailure('QR no encontrado en base de datos', code: 'QR_NOT_FOUND');

  factory QrFailure.deactivated() =>
      const QrFailure('Este QR ha sido desactivado', code: 'QR_DEACTIVATED');

  factory QrFailure.alreadyUsedToday() =>
      const QrFailure('Este QR ya fue utilizado hoy', code: 'ALREADY_USED_TODAY');

  factory QrFailure.maxUsesReached(int maxUses) =>
      QrFailure('Máximo de usos alcanzado ($maxUses)', code: 'MAX_USES_REACHED');

  factory QrFailure.invitationExpired() =>
      const QrFailure('La invitación ha expirado', code: 'INVITATION_EXPIRED');

  factory QrFailure.invalidOperationalDay() =>
      const QrFailure('La invitación no es válida para esta noche', code: 'INVALID_OPERATIONAL_DAY');

  factory QrFailure.notForToday() =>
      const QrFailure('Este QR no corresponde a la noche operativa de hoy', code: 'NOT_FOR_TODAY');

  factory QrFailure.noActiveOperationalDay() =>
      const QrFailure('No hay noche operativa activa en este momento', code: 'NO_ACTIVE_OPERATIONAL_DAY');
}

/// Error genérico / inesperado (legacy alias para UnknownFailure)
class UnexpectedFailure extends Failure {
  final Object? originalError;
  final StackTrace? stackTrace;

  const UnexpectedFailure(
    super.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, originalError];
}
