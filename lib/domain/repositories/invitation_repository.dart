import 'package:dartz/dartz.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

abstract class InvitationRepository {
  /// Obtiene todas las invitaciones (isInvitation = true)
  Future<Either<Failure, List<GuestModel>>> getAll();

  /// Obtiene todas las invitaciones creadas por un usuario
  Future<Either<Failure, List<GuestModel>>> getByUser(String userId);

  /// Crea una nueva invitación
  Future<Either<Failure, String>> create(GuestModel invitation);

  /// Actualiza una invitación existente
  Future<Either<Failure, void>> update(GuestModel invitation);

  /// Elimina una invitación (valida ownership)
  Future<Either<Failure, void>> delete(String id, String currentUserId);

  /// Activa o desactiva una invitación
  Future<Either<Failure, void>> toggleStatus(String id, bool isActive);

  /// Stream de invitaciones por usuario en tiempo real
  Stream<Either<Failure, List<GuestModel>>> watchByUser(String userId);

  /// Obtiene invitaciones activas de un usuario
  Future<Either<Failure, List<GuestModel>>> getActiveByUser(String userId);
}
