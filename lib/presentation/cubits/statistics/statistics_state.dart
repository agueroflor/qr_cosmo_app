part of 'statistics_cubit.dart';

/// Estado base para el cubit de estadísticas
sealed class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - antes de cargar datos
class StatisticsInitial extends StatisticsState {
  const StatisticsInitial();
}

/// Estado de carga
class StatisticsLoading extends StatisticsState {
  final String message;

  const StatisticsLoading({this.message = 'Cargando estadísticas...'});

  @override
  List<Object?> get props => [message];
}

/// Estado de éxito con datos cargados
class StatisticsLoaded extends StatisticsState {
  final StatisticsModel statistics;

  const StatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

/// Estado de error
class StatisticsError extends StatisticsState {
  final String message;
  final String? code;

  const StatisticsError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}
