import 'package:dartz/dartz.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/data/models/statistics_model.dart';

/// Repositorio abstracto para estadísticas
abstract class StatisticsRepository {
  /// Obtiene estadísticas generales completas
  Future<Either<Failure, StatisticsModel>> getStatistics();

  /// Obtiene visitas agrupadas por hora para un día
  Future<Either<Failure, Map<int, int>>> getVisitsByHour(DateTime date);

  /// Obtiene los guests con más visitas
  Future<Either<Failure, List<GuestFrequency>>> getTopGuests({int limit = 10});

  /// Obtiene estadísticas de fines de semana
  Future<Either<Failure, WeekendStats>> getWeekendStats();

  /// Obtiene las visitas diarias de la última semana
  Future<Either<Failure, List<DailyVisits>>> getDailyVisitsLastWeek();

  /// Obtiene los guests frecuentes en fines de semana
  Future<Either<Failure, List<GuestFrequency>>> getFrequentWeekendGuests({
    int limit = 10,
  });

  /// Obtiene los guests con QR no utilizado
  Future<Either<Failure, List<GuestFrequency>>> getUnusedQrGuests();
}
