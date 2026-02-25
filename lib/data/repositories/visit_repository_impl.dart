import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:qr_cosmo_app/data/models/visit_model.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/repositories/visit_repository.dart';

class VisitRepositoryImpl implements VisitRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'visits';

  VisitRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _visitsRef =>
      _firestore.collection(_collection);

  @override
  Future<Either<Failure, String>> create(VisitModel visit) async {
    try {
      final docRef = await _visitsRef.add(visit.toMap());
      return Right(docRef.id);
    } catch (e, stackTrace) {
      debugPrint('Error creating visit: $e');
      return Left(UnexpectedFailure(
        'Error registrando visita',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> createBatch(List<VisitModel> visits) async {
    try {
      if (visits.isEmpty) return const Right(null);

      final batch = _firestore.batch();
      for (final visit in visits) {
        final docRef = _visitsRef.doc();
        batch.set(docRef, visit.toMap());
      }
      await batch.commit();
      return const Right(null);
    } catch (e, stackTrace) {
      debugPrint('Error creating visits batch: $e');
      return Left(UnexpectedFailure(
        'Error registrando visitas en batch',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, List<VisitModel>>> getLastVisits(
    String guestId, {
    int limit = 50,
  }) async {
    try {
      final query = await _visitsRef
          .where('guestId', isEqualTo: guestId)
          .orderBy('scannedAt', descending: true)
          .limit(limit)
          .get();

      final visits = query.docs
          .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(visits);
    } catch (e, stackTrace) {
      debugPrint('Error getting last visits: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo últimas visitas',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, List<VisitModel>>> getByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _visitsRef
          .where('scannedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('scannedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('scannedAt', descending: true)
          .get();

      final visits = query.docs
          .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(visits);
    } catch (e, stackTrace) {
      debugPrint('Error getting visits by date range: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo visitas por rango de fechas',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, List<VisitModel>>> getTodayVisits() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return getByDateRange(startDate: startOfDay, endDate: endOfDay);
  }

  @override
  Stream<Either<Failure, List<VisitModel>>> watchGuestVisits(String guestId) {
    return _visitsRef
        .where('guestId', isEqualTo: guestId)
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        final visits = snapshot.docs
            .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
            .toList();
        return Right<Failure, List<VisitModel>>(visits);
      } catch (e, stackTrace) {
        return Left<Failure, List<VisitModel>>(UnexpectedFailure(
          'Error en stream de visitas',
          originalError: e,
          stackTrace: stackTrace,
        ));
      }
    });
  }

  @override
  Stream<Either<Failure, List<VisitModel>>> watchAll({int limit = 100}) {
    return _visitsRef
        .orderBy('scannedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      try {
        final visits = snapshot.docs
            .map((doc) => VisitModel.fromMap(doc.data(), doc.id))
            .toList();
        return Right<Failure, List<VisitModel>>(visits);
      } catch (e, stackTrace) {
        return Left<Failure, List<VisitModel>>(UnexpectedFailure(
          'Error en stream de visitas',
          originalError: e,
          stackTrace: stackTrace,
        ));
      }
    });
  }

  @override
  Future<Either<Failure, Map<int, int>>> getVisitsByHour(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final query = await _visitsRef
          .where('scannedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scannedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final Map<int, int> hourlyVisits = {};

      // Inicializar todas las horas con 0
      for (int i = 0; i < 24; i++) {
        hourlyVisits[i] = 0;
      }

      for (final doc in query.docs) {
        final data = doc.data();
        final timestamp = data['scannedAt'] as Timestamp;
        final visitDate = timestamp.toDate();
        final hour = visitDate.hour;
        hourlyVisits[hour] = (hourlyVisits[hour] ?? 0) + 1;
      }

      return Right(hourlyVisits);
    } catch (e, stackTrace) {
      debugPrint('Error getting visits by hour: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo visitas por hora',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}
