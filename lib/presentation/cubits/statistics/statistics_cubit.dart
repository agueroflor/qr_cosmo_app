import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_cosmo_app/domain/repositories/statistics_repository.dart';
import 'package:qr_cosmo_app/data/models/statistics_model.dart';

part 'statistics_state.dart';

/// Cubit para gestionar las estadísticas de la aplicación
class StatisticsCubit extends Cubit<StatisticsState> {
  final StatisticsRepository _statisticsRepository;

  StatisticsCubit(this._statisticsRepository) : super(const StatisticsInitial());

  /// Carga las estadísticas desde el repositorio
  Future<void> loadStatistics() async {
    emit(const StatisticsLoading());

    final result = await _statisticsRepository.getStatistics();

    result.fold(
      (failure) => emit(StatisticsError(failure.message, code: failure.code)),
      (statistics) => emit(StatisticsLoaded(statistics)),
    );
  }

  /// Refresca las estadísticas (alias para loadStatistics)
  Future<void> refresh() => loadStatistics();
}
