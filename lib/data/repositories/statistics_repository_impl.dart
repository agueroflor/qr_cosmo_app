import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/data/models/statistics_model.dart';
import 'package:qr_cosmo_app/domain/repositories/statistics_repository.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final FirebaseFirestore _firestore;

  StatisticsRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _guestsRef =>
      _firestore.collection('guests');

  CollectionReference<Map<String, dynamic>> get _visitsRef =>
      _firestore.collection('visits');

  @override
  Future<Either<Failure, StatisticsModel>> getStatistics() async {
    try {
      // Obtener contadores básicos
      final guestsSnapshot = await _guestsRef.get();
      final visitsSnapshot = await _visitsRef.get();

      final totalGuests = guestsSnapshot.docs.length;
      final totalVisits = visitsSnapshot.docs.length;

      // Invitados activos (con totalVisits > 0)
      final activeGuests = guestsSnapshot.docs
          .where((doc) => (doc.data()['totalVisits'] ?? 0) > 0)
          .length;

      // Visitas de hoy
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay =
          DateTime(today.year, today.month, today.day, 23, 59, 59);

      final todayQuery = await _visitsRef
          .where('scannedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scannedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Visitas de esta semana
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final thisWeekQuery = await _visitsRef
          .where('scannedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      // Visitas de este mes
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      final thisMonthQuery = await _visitsRef
          .where('scannedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo))
          .get();

      // Promedio de visitas por invitado
      final averageVisitsPerGuest =
          totalGuests > 0 ? totalVisits / totalGuests : 0.0;

      // Top invitados frecuentes
      final topFrequentGuests = _getTopFrequentGuests(guestsSnapshot.docs);

      // Visitas diarias de la última semana
      final dailyVisitsResult = await getDailyVisitsLastWeek();
      final dailyVisitsLastWeek = dailyVisitsResult.fold(
        (failure) => <DailyVisits>[],
        (visits) => visits,
      );

      // Estadísticas de fines de semana
      final weekendStatsResult = await getWeekendStats();
      final weekendStats = weekendStatsResult.fold(
        (failure) => WeekendStats(
          totalWeekendVisits: 0,
          fridayVisits: 0,
          saturdayVisits: 0,
          uniqueWeekendGuests: 0,
          averageWeekendVisits: 0,
          lastWeekends: [],
        ),
        (stats) => stats,
      );

      // Invitados con QR no utilizado
      final unusedQrGuests = _getUnusedQrGuests(guestsSnapshot.docs);

      // Intentos fallidos (vacío por ahora)
      final failedAttempts = <FailedAttempt>[];

      // Invitados frecuentes en fines de semana
      final frequentWeekendResult = await getFrequentWeekendGuests();
      final frequentWeekendGuests = frequentWeekendResult.fold(
        (failure) => <GuestFrequency>[],
        (guests) => guests,
      );

      return Right(StatisticsModel(
        totalGuests: totalGuests,
        totalVisits: totalVisits,
        activeGuests: activeGuests,
        todayVisits: todayQuery.docs.length,
        thisWeekVisits: thisWeekQuery.docs.length,
        thisMonthVisits: thisMonthQuery.docs.length,
        averageVisitsPerGuest: averageVisitsPerGuest,
        topFrequentGuests: topFrequentGuests,
        dailyVisitsLastWeek: dailyVisitsLastWeek,
        weekendStats: weekendStats,
        unusedQrGuests: unusedQrGuests,
        failedAttempts: failedAttempts,
        frequentWeekendGuests: frequentWeekendGuests,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error getting statistics: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo estadísticas',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
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

  @override
  Future<Either<Failure, List<GuestFrequency>>> getTopGuests({
    int limit = 10,
  }) async {
    try {
      final guestsSnapshot = await _guestsRef.get();
      final topGuests = _getTopFrequentGuests(guestsSnapshot.docs);
      return Right(topGuests.take(limit).toList());
    } catch (e, stackTrace) {
      debugPrint('Error getting top guests: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo top invitados',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, WeekendStats>> getWeekendStats() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final query = await _visitsRef
          .where('scannedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      int totalWeekendVisits = 0;
      int fridayVisits = 0;
      int saturdayVisits = 0;
      Set<String> uniqueWeekendGuests = {};
      List<WeekendDayStats> lastWeekends = [];

      for (final doc in query.docs) {
        final data = doc.data();
        final timestamp = data['scannedAt'] as Timestamp;
        final date = timestamp.toDate();
        final weekday = date.weekday;

        if (weekday == 5 || weekday == 6) {
          totalWeekendVisits++;
          uniqueWeekendGuests.add(data['guestId'] ?? '');

          if (weekday == 5) {
            fridayVisits++;
          } else {
            saturdayVisits++;
          }
        }
      }

      // Obtener estadísticas de los últimos fines de semana
      final today = DateTime.now();
      for (int i = 0; i < 14; i++) {
        final checkDate = today.subtract(Duration(days: i));
        if (checkDate.weekday == 5 || checkDate.weekday == 6) {
          final dayVisits = query.docs.where((doc) {
            final data = doc.data();
            final timestamp = data['scannedAt'] as Timestamp;
            final visitDate = timestamp.toDate();
            return visitDate.year == checkDate.year &&
                visitDate.month == checkDate.month &&
                visitDate.day == checkDate.day;
          }).length;

          lastWeekends.add(WeekendDayStats(
            date: checkDate,
            visitCount: dayVisits,
            dayName: checkDate.weekday == 5 ? 'Viernes' : 'Sábado',
          ));
        }
      }

      lastWeekends.sort((a, b) => b.date.compareTo(a.date));

      final averageWeekendVisits = lastWeekends.isNotEmpty
          ? lastWeekends.map((w) => w.visitCount).reduce((a, b) => a + b) /
              lastWeekends.length
          : 0.0;

      return Right(WeekendStats(
        totalWeekendVisits: totalWeekendVisits,
        fridayVisits: fridayVisits,
        saturdayVisits: saturdayVisits,
        uniqueWeekendGuests: uniqueWeekendGuests.length,
        averageWeekendVisits: averageWeekendVisits,
        lastWeekends: lastWeekends.take(6).toList(),
      ));
    } catch (e, stackTrace) {
      debugPrint('Error getting weekend stats: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo estadísticas de fin de semana',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, List<DailyVisits>>> getDailyVisitsLastWeek() async {
    try {
      final today = DateTime.now();
      final weekAgo = today.subtract(const Duration(days: 7));

      final query = await _visitsRef
          .where('scannedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      final Map<String, int> dailyCounts = {};

      for (final doc in query.docs) {
        final data = doc.data();
        final timestamp = data['scannedAt'] as Timestamp;
        final date = timestamp.toDate();
        final dayKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        dailyCounts[dayKey] = (dailyCounts[dayKey] ?? 0) + 1;
      }

      final List<DailyVisits> dailyVisits = [];
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        dailyVisits.add(DailyVisits(
          date: date,
          visitCount: dailyCounts[dayKey] ?? 0,
        ));
      }

      return Right(dailyVisits);
    } catch (e, stackTrace) {
      debugPrint('Error getting daily visits: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo visitas diarias',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, List<GuestFrequency>>> getFrequentWeekendGuests({
    int limit = 10,
  }) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final visitsQuery = await _visitsRef
          .where('scannedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final weekendVisits = visitsQuery.docs.where((doc) {
        final data = doc.data();
        final timestamp = data['scannedAt'] as Timestamp;
        final date = timestamp.toDate();
        return date.weekday == 5 || date.weekday == 6;
      }).toList();

      Map<String, int> guestWeekendVisits = {};
      Map<String, String> guestNames = {};
      Map<String, String> guestDnis = {};
      Map<String, DateTime> lastWeekendVisits = {};

      for (final visit in weekendVisits) {
        final data = visit.data();
        final guestId = data['guestId'] ?? '';
        final guestName = data['guestName'] ?? '';
        final dni = data['dni'] ?? '';
        final timestamp = data['scannedAt'] as Timestamp;
        final visitDate = timestamp.toDate();

        guestWeekendVisits[guestId] = (guestWeekendVisits[guestId] ?? 0) + 1;
        guestNames[guestId] = guestName;
        guestDnis[guestId] = dni;

        if (lastWeekendVisits[guestId] == null ||
            visitDate.isAfter(lastWeekendVisits[guestId]!)) {
          lastWeekendVisits[guestId] = visitDate;
        }
      }

      final frequentWeekendGuests = guestWeekendVisits.entries
          .where((entry) => entry.value > 0)
          .map((entry) => GuestFrequency(
                guestId: entry.key,
                name: guestNames[entry.key] ?? 'Sin nombre',
                dni: guestDnis[entry.key] ?? 'Sin DNI',
                visitCount: entry.value,
                lastVisit: lastWeekendVisits[entry.key] ?? DateTime.now(),
              ))
          .toList();

      frequentWeekendGuests.sort((a, b) => b.visitCount.compareTo(a.visitCount));

      return Right(frequentWeekendGuests.take(limit).toList());
    } catch (e, stackTrace) {
      debugPrint('Error getting frequent weekend guests: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo invitados frecuentes de fin de semana',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Either<Failure, List<GuestFrequency>>> getUnusedQrGuests() async {
    try {
      final guestsSnapshot = await _guestsRef.get();
      final unusedGuests = _getUnusedQrGuests(guestsSnapshot.docs);
      return Right(unusedGuests);
    } catch (e, stackTrace) {
      debugPrint('Error getting unused QR guests: $e');
      return Left(UnexpectedFailure(
        'Error obteniendo invitados con QR no utilizado',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS HELPER
  // ══════════════════════════════════════════════════════════════════════════

  List<GuestFrequency> _getTopFrequentGuests(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final frequencies = docs
        .map((doc) {
          final data = doc.data();
          final visitCount = data['totalVisits'] ?? 0;
          if (visitCount > 0) {
            return GuestFrequency(
              guestId: doc.id,
              name: data['name'] ?? '',
              dni: data['dni'] ?? '',
              visitCount: visitCount,
              lastVisit: data['lastVisit'] != null
                  ? (data['lastVisit'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          }
          return null;
        })
        .where((freq) => freq != null)
        .cast<GuestFrequency>()
        .toList();

    frequencies.sort((a, b) => b.visitCount.compareTo(a.visitCount));
    return frequencies.take(10).toList();
  }

  List<GuestFrequency> _getUnusedQrGuests(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .where((doc) {
          final data = doc.data();
          return (data['totalVisits'] ?? 0) == 0 && (data['isActive'] ?? true);
        })
        .map((doc) {
          final data = doc.data();
          return GuestFrequency(
            guestId: doc.id,
            name: data['name'] ?? 'Sin nombre',
            dni: data['dni'] ?? 'Sin DNI',
            visitCount: 0,
            lastVisit: DateTime.now(),
          );
        })
        .toList();
  }
}
