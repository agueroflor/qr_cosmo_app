// lib/data/repositories/invitation_repository_impl.dart
// Implementación del repositorio de invitaciones usando Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/repositories/invitation_repository.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'guests';

  InvitationRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _guestsRef =>
      _firestore.collection(_collection);

  @override
  Future<Either<Failure, List<GuestModel>>> getAll() async {
    try {
      final query = await _guestsRef
          .where('isInvitation', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final invitations = query.docs
          .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(invitations);
    } catch (e, stackTrace) {
      debugPrint('Error getting all invitations: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo invitaciones',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, List<GuestModel>>> getByUser(String userId) async {
    try {
      final query = await _guestsRef
          .where('isInvitation', isEqualTo: true)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final invitations = query.docs
          .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(invitations);
    } catch (e, stackTrace) {
      debugPrint('Error getting invitations by user: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo invitaciones del usuario',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, String>> create(GuestModel invitation) async {
    try {
      // Asegurar que es una invitación
      final invitationMap = invitation.toMap();
      invitationMap['isInvitation'] = true;
      if (invitationMap['ownerId'] == null) {
        invitationMap['ownerId'] = invitation.createdBy;
      }

      final docRef = await _guestsRef.add(invitationMap);
      return Right(docRef.id);
    } catch (e, stackTrace) {
      debugPrint('Error creating invitation: $e');
      return Left(UnexpectedFailure(
        'Error creando invitación',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> update(GuestModel invitation) async {
    try {
      await _guestsRef.doc(invitation.id).update(invitation.toMap());
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error updating invitation: $e');
      return Left(UnexpectedFailure(
        'Error actualizando invitación',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id, String currentUserId) async {
    try {
      // Obtener la invitación para validar ownership
      final invitationDoc = await _guestsRef.doc(id).get();

      if (!invitationDoc.exists) {
        return Left(DatabaseFailure.notFound('Invitación'));
      }

      final invitationData = invitationDoc.data()!;
      final ownerId = invitationData['ownerId'] ?? invitationData['createdBy'];

      // Validar ownership
      if (ownerId != currentUserId) {
        return const Left(DatabaseFailure(
          'No tienes permiso para eliminar esta invitación.',
          code: 'PERMISSION_DENIED',
        ));
      }

      // Eliminar visitas relacionadas y la invitación en batch
      final visitsQuery = await _firestore
          .collection('visits')
          .where('guestId', isEqualTo: id)
          .get();

      final batch = _firestore.batch();
      for (final visitDoc in visitsQuery.docs) {
        batch.delete(visitDoc.reference);
      }
      batch.delete(_guestsRef.doc(id));

      await batch.commit();
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error deleting invitation: $e');
      return Left(UnexpectedFailure(
        'Error eliminando invitación',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> toggleStatus(String id, bool isActive) async {
    try {
      await _guestsRef.doc(id).update({'isActive': isActive});
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error toggling invitation status: $e');
      return Left(UnexpectedFailure(
        'Error actualizando estado',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Stream<Either<Failure, List<GuestModel>>> watchByUser(String userId) {
    return _guestsRef
        .where('isInvitation', isEqualTo: true)
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        final invitations = snapshot.docs
            .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
            .toList();
        return Right<Failure, List<GuestModel>>(invitations);
      } catch (e, stackTrace) {
        return Left<Failure, List<GuestModel>>(UnexpectedFailure(
          'Error en stream de invitaciones',
          originalError: e,
          stackTrace: stackTrace,
        ));
      }
    });
  }

  @override
  Future<Either<Failure, List<GuestModel>>> getActiveByUser(
      String userId) async {
    try {
      final query = await _guestsRef
          .where('isInvitation', isEqualTo: true)
          .where('createdBy', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final invitations = query.docs
          .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(invitations);
    } catch (e, stackTrace) {
      debugPrint('Error getting active invitations: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo invitaciones activas',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}
