import 'package:dartz/dartz.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/data/models/user_model.dart';

abstract class AuthRepository {

  Stream<UserModel?> get authStateChanges;

  Future<Either<Failure, UserModel?>> getCurrentUser();

  Future<Either<Failure, UserModel>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserModel>> registerWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  bool get isAuthenticated;
}
