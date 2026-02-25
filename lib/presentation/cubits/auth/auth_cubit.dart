import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'package:qr_cosmo_app/domain/entities/user_role.dart';
import 'package:qr_cosmo_app/domain/repositories/auth_repository.dart';
import 'package:qr_cosmo_app/domain/usecases/auth/validate_admin_access_usecase.dart';
import 'package:qr_cosmo_app/data/models/user_model.dart';
import 'auth_state.dart';

export 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final ValidateAdminAccessUseCase _validateAdminAccess;
  StreamSubscription<UserModel?>? _authStateSubscription;

  AuthCubit(this._authRepository, this._validateAdminAccess)
      : super(const AuthInitial()) {
    _init();
  }

  /// Inicializa el cubit y escucha cambios de autenticación
  void _init() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (error) {
        debugPrint('Error in auth state stream: $error');
        emit(AuthError(error.toString()));
      },
    );
  }

  /// Maneja cambios en el estado de autenticación
  void _onAuthStateChanged(UserModel? user) {
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Inicia sesión con email y contraseña
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading(message: 'Iniciando sesión...'));

    final result = await _authRepository.signInWithEmail(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Registra un nuevo usuario
  ///
  /// [adminPassword] es requerido para roles privilegiados (generator, admin).
  /// La validación se delega al UseCase / repositorio.
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? adminPassword,
  }) async {
    // Validar acceso administrativo si el rol lo requiere
    if (role.requiresAdminValidation) {
      final validationResult = await _validateAdminAccess(
        ValidateAdminAccessParams(
          accessCode: adminPassword ?? '',
          requestedRole: role,
        ),
      );

      final failed = validationResult.fold(
        (failure) => failure,
        (_) => null,
      );

      if (failed != null) {
        emit(AuthError(failed.message, code: failed.code));
        return;
      }
    }

    emit(const AuthLoading(message: 'Creando cuenta...'));

    final result = await _authRepository.registerWithEmail(
      email: email,
      password: password,
      name: name,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Cierra la sesión actual
  Future<void> signOut() async {
    emit(const AuthLoading(message: 'Cerrando sesión...'));

    final result = await _authRepository.signOut();

    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  /// Envía email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    emit(const AuthLoading(message: 'Enviando email...'));

    final result = await _authRepository.sendPasswordResetEmail(email);

    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (_) {
        emit(const AuthUnauthenticated());
      },
    );
  }

  /// Verifica el usuario actual y actualiza el estado
  Future<void> checkCurrentUser() async {
    emit(const AuthLoading(message: 'Verificando sesión...'));

    final result = await _authRepository.getCurrentUser();

    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  /// Retorna el usuario actual si está autenticado
  UserModel? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  /// Verifica si hay un usuario autenticado
  bool get isAuthenticated => state is AuthAuthenticated;

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
