// lib/data/repositories/auth_repository_impl.dart
// Implementación del repositorio de autenticación usando Firebase

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/repositories/auth_repository.dart';
import 'package:qr_cosmo_app/data/models/user_model.dart';
import 'package:qr_cosmo_app/domain/entities/user_role.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl(this._auth, this._firestore);

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _loadUserModel(user.uid);
    });
  }

  @override
  bool get isAuthenticated => _auth.currentUser != null;

  @override
  Future<Either<Failure, UserModel?>> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Right(null);
      }

      final userModel = await _loadUserModel(user.uid);
      return Right(userModel);
    } catch (e, stackTrace) {
      debugPrint('Error getting current user: $e');
      return Left(UnexpectedFailure(
        'Error al obtener usuario actual',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return Left(AuthFailure.userNotFound());
      }

      final userModel = await _loadUserModel(credential.user!.uid);
      if (userModel == null) {
        return Left(AuthFailure.userNotFound());
      }

      return Right(userModel);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Error signing in: $e');
      return Left(UnexpectedFailure(
        'Error inesperado al iniciar sesión',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, UserModel>> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return const Left(AuthFailure('Error al crear usuario'));
      }

      final newUser = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: UserRole.reader, // Por defecto es reader
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toMap());

      return Right(newUser);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Error registering: $e');
      return Left(UnexpectedFailure(
        'Error inesperado al registrar',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _auth.signOut();
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error signing out: $e');
      return Left(UnexpectedFailure(
        'Error al cerrar sesión',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthError(e));
    } catch (e, stackTrace) {
      return Left(UnexpectedFailure(
        'Error al enviar email de recuperación',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS
  // ══════════════════════════════════════════════════════════════════════════

  Future<UserModel?> _loadUserModel(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error loading user model: $e');
      return null;
    }
  }

  AuthFailure _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
        return AuthFailure.invalidCredentials();
      case 'invalid-credential':
        return AuthFailure.invalidCredentials();
      case 'invalid-email':
        return const AuthFailure('Email inválido', code: 'INVALID_EMAIL');
      case 'user-disabled':
        return const AuthFailure('Usuario deshabilitado', code: 'USER_DISABLED');
      case 'too-many-requests':
        return const AuthFailure(
          'Demasiados intentos. Intenta más tarde',
          code: 'TOO_MANY_REQUESTS',
        );
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse();
      case 'weak-password':
        return AuthFailure.weakPassword();
      default:
        return AuthFailure(
          e.message ?? 'Error de autenticación',
          code: e.code,
        );
    }
  }
}
