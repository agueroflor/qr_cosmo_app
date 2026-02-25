import 'package:dartz/dartz.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

abstract class GuestRepository {
  /// Obtiene un guest por su código QR
  Future<Either<Failure, GuestModel?>> getByQrCode(String qrCode);

  /// Obtiene un guest por su ID
  Future<Either<Failure, GuestModel?>> getById(String id);

  /// Obtiene un guest por su DNI
  Future<Either<Failure, GuestModel?>> getByDni(String dni);

  /// Crea un nuevo guest
  Future<Either<Failure, String>> create(GuestModel guest);

  /// Actualiza un guest existente
  Future<Either<Failure, void>> update(GuestModel guest);

  /// Actualiza solo nombre y DNI de un guest
  Future<Either<Failure, void>> updateInfo(String id, String name, String dni);

  /// Elimina un guest (valida ownership)
  Future<Either<Failure, void>> delete(String id, String currentUserId);

  /// Marca un QR como usado (incrementa contador de usos)
  Future<Either<Failure, void>> markAsUsed(String id, {int count = 1});

  /// Activa o desactiva un guest
  Future<Either<Failure, void>> toggleStatus(String id, bool isActive);

  /// Obtiene todos los guests (solo los que NO son invitaciones)
  Future<Either<Failure, List<GuestModel>>> getAll();

  /// Obtiene todos los guests creados por un usuario
  Future<Either<Failure, List<GuestModel>>> getByCreator(String creatorId);

  /// Stream de guests en tiempo real (para listas)
  Stream<Either<Failure, List<GuestModel>>> watchAll({int limit = 50});

  /// Stream de guests por creador en tiempo real
  Stream<Either<Failure, List<GuestModel>>> watchByCreator(String creatorId);
}
