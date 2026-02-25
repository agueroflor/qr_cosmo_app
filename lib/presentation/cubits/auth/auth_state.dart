import 'package:equatable/equatable.dart';
import 'package:qr_cosmo_app/data/models/user_model.dart';
import 'package:qr_cosmo_app/domain/entities/user_role.dart';

/// Estado base para autenticación
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial: verificando si hay sesión activa
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado: cargando (durante login, logout, registro)
class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Estado: usuario autenticado
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user.id, user.email, user.role];

  /// Verifica si el usuario puede generar QR
  bool get canGenerateQR => user.role.canGenerateQR;

  /// Verifica si el usuario puede leer QR
  bool get canReadQR => user.role.canReadQR;

  /// Verifica si el usuario puede ver estadísticas
  bool get canViewStatistics => user.role.canViewStatistics;
}

/// Estado: sin autenticación
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado: error de autenticación
class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}
