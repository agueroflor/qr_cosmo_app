// lib/data/repositories/guest_repository_impl.dart
// Implementación del repositorio de guests usando Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

class GuestRepositoryImpl implements GuestRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'guests';

  GuestRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _guestsRef =>
      _firestore.collection(_collection);

  @override
  Future<Either<Failure, GuestModel?>> getByQrCode(String qrCode) async {
    try {
      final query = await _guestsRef
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return Right(GuestModel.fromMap(doc.data(), doc.id));
      }
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error getting guest by QR: $e');
      return Left(UnexpectedFailure(
        'Error buscando por QR',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, GuestModel?>> getById(String id) async {
    try {
      final doc = await _guestsRef.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Right(GuestModel.fromMap(doc.data()!, doc.id));
      }
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error getting guest by ID: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo invitado',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, GuestModel?>> getByDni(String dni) async {
    try {
      final query = await _guestsRef
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return Right(GuestModel.fromMap(doc.data(), doc.id));
      }
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error getting guest by DNI: $e');
      return Left(UnexpectedFailure(
        'Error buscando por DNI',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, String>> create(GuestModel guest) async {
    try {
      final guestMap = guest.toMap();
      // Asegurar que siempre tenga ownerId
      if (guestMap['ownerId'] == null) {
        guestMap['ownerId'] = guest.createdBy;
      }
      final docRef = await _guestsRef.add(guestMap);
      return Right(docRef.id);
    } catch (e, stackTrace) {
      debugPrint('Error creating guest: $e');
      return Left(UnexpectedFailure(
        'Error creando invitado',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> update(GuestModel guest) async {
    try {
      await _guestsRef.doc(guest.id).update(guest.toMap());
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error updating guest: $e');
      return Left(UnexpectedFailure(
        'Error actualizando invitado',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> updateInfo(
      String id, String name, String dni) async {
    try {
      await _guestsRef.doc(id).update({
        'name': name,
        'dni': dni,
      });
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error updating guest info: $e');
      return Left(UnexpectedFailure(
        'Error actualizando información',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id, String currentUserId) async {
    try {
      // Obtener el guest para validar ownership
      final guestDoc = await _guestsRef.doc(id).get();

      if (!guestDoc.exists) {
        return Left(DatabaseFailure.notFound('QR'));
      }

      final guestData = guestDoc.data()!;
      final ownerId = guestData['ownerId'] ?? guestData['createdBy'];

      // Validar ownership
      if (ownerId != currentUserId) {
        return const Left(DatabaseFailure(
          'No tienes permiso para eliminar este QR. Solo el dueño puede eliminarlo.',
          code: 'PERMISSION_DENIED',
        ));
      }

      // Eliminar visitas relacionadas y el guest en batch
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
      debugPrint('Error deleting guest: $e');
      if (e.toString().contains('PERMISSION_DENIED')) {
        return Left(DatabaseFailure.permissionDenied());
      }
      return Left(UnexpectedFailure(
        'Error eliminando invitado',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> markAsUsed(String id, {int count = 1}) async {
    try {
      final guestRef = _guestsRef.doc(id);
      final now = DateTime.now();

      await _firestore.runTransaction((transaction) async {
        final guestDoc = await transaction.get(guestRef);
        if (guestDoc.exists) {
          final currentVisits = guestDoc.data()?['totalVisits'] ?? 0;
          transaction.update(guestRef, {
            'totalVisits': currentVisits + count,
            'lastVisit': Timestamp.fromDate(now),
            'lastUsedDate': Timestamp.fromDate(now),
            'isActive': true,
            'lastSuccessfulEntry': Timestamp.fromDate(now),
          });
        }
      });
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error marking as used: $e');
      return Left(UnexpectedFailure(
        'Error marcando QR como usado',
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
      debugPrint('Error toggling status: $e');
      return Left(UnexpectedFailure(
        'Error actualizando estado',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, List<GuestModel>>> getAll() async {
    try {
      final query = await _guestsRef
          .where('isInvitation', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final guests = query.docs
          .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(guests);
    } catch (e, stackTrace) {
      debugPrint('Error getting all guests: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo invitados',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, List<GuestModel>>> getByCreator(
      String creatorId) async {
    try {
      final query = await _guestsRef
          .where('createdBy', isEqualTo: creatorId)
          .where('isInvitation', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final guests = query.docs
          .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(guests);
    } catch (e, stackTrace) {
      debugPrint('Error getting guests by creator: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo invitados del usuario',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Stream<Either<Failure, List<GuestModel>>> watchAll({int limit = 50}) {
    return _guestsRef
        .where('isInvitation', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      try {
        final guests = snapshot.docs
            .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
            .toList();
        return Right<Failure, List<GuestModel>>(guests);
      } catch (e, stackTrace) {
        return Left<Failure, List<GuestModel>>(UnexpectedFailure(
          'Error en stream de invitados',
          originalError: e,
          stackTrace: stackTrace,
        ));
      }
    });
  }

  @override
  Stream<Either<Failure, List<GuestModel>>> watchByCreator(String creatorId) {
    return _guestsRef
        .where('createdBy', isEqualTo: creatorId)
        .where('isInvitation', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        final guests = snapshot.docs
            .map((doc) => GuestModel.fromMap(doc.data(), doc.id))
            .toList();
        return Right<Failure, List<GuestModel>>(guests);
      } catch (e, stackTrace) {
        return Left<Failure, List<GuestModel>>(UnexpectedFailure(
          'Error en stream de invitados',
          originalError: e,
          stackTrace: stackTrace,
        ));
      }
    });
  }
}
