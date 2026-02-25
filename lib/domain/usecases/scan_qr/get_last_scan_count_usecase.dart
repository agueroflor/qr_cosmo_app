import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/core/usecases/usecase.dart';
import 'package:qr_cosmo_app/domain/repositories/visit_repository.dart';

class GetLastScanCountUseCase implements UseCase<int, GetLastScanCountParams> {
  final VisitRepository _visitRepository;

  GetLastScanCountUseCase(this._visitRepository);

  @override
  Future<Either<Failure, int>> call(GetLastScanCountParams params) async {
    try {
      final result = await _visitRepository.getLastVisits(
        params.guestId,
        limit: 100,
      );

      return result.fold(
        (failure) => Left(failure),
        (visits) {
          // Filtrar visitas de los últimos 3 minutos
          final now = DateTime.now();
          final recentVisits = visits.where((visit) {
            final difference = now.difference(visit.scannedAt);
            return difference.inMinutes < 3;
          }).toList();

          return Right(recentVisits.length);
        },
      );
    } catch (e, stackTrace) {
      return Left(UnexpectedFailure(
        'Error obteniendo conteo de escaneos',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}

class GetLastScanCountParams extends Equatable {
  final String guestId;

  const GetLastScanCountParams({required this.guestId});

  @override
  List<Object?> get props => [guestId];
}
