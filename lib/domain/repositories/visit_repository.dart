import 'package:dartz/dartz.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/data/models/visit_model.dart';

abstract class VisitRepository {
  /// Crea una nueva visita
  Future<Either<Failure, String>> create(VisitModel visit);

  /// Crea múltiples visitas en batch (para invitaciones grupales)
  Future<Either<Failure, void>> createBatch(List<VisitModel> visits);

  /// Obtiene las últimas visitas de un guest
  Future<Either<Failure, List<VisitModel>>> getLastVisits(
    String guestId, {
    int limit = 50,
  });

  /// Obtiene visitas en un rango de fechas
  Future<Either<Failure, List<VisitModel>>> getByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Obtiene visitas de hoy
  Future<Either<Failure, List<VisitModel>>> getTodayVisits();

  /// Stream de visitas de un guest en tiempo real
  Stream<Either<Failure, List<VisitModel>>> watchGuestVisits(String guestId);

  /// Stream de todas las visitas en tiempo real
  Stream<Either<Failure, List<VisitModel>>> watchAll({int limit = 100});

  /// Cuenta visitas por hora para un día específico
  Future<Either<Failure, Map<int, int>>> getVisitsByHour(DateTime date);
}
