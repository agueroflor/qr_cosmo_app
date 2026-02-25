import 'package:dartz/dartz.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';

/// Interfaz base para UseCases con parámetros
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Interfaz para UseCases sin parámetros
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Interfaz para UseCases que retornan Stream
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// Clase para indicar que un UseCase no requiere parámetros
class NoParams {
  const NoParams();
}
