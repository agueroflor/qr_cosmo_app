import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/data/models/models.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/presentation/presentation.dart';

class MockStatisticsRepository extends Mock implements StatisticsRepository {}

void main() {
  late StatisticsCubit cubit;
  late MockStatisticsRepository mockRepository;

  final testStatistics = StatisticsModel(
    totalGuests: 100,
    totalVisits: 500,
    activeGuests: 80,
    todayVisits: 10,
    thisWeekVisits: 50,
    thisMonthVisits: 200,
    averageVisitsPerGuest: 5.0,
    topFrequentGuests: [],
    dailyVisitsLastWeek: [],
    failedAttempts: [],
    weekendStats: WeekendStats(
      totalWeekendVisits: 100,
      fridayVisits: 40,
      saturdayVisits: 60,
      uniqueWeekendGuests: 50,
      averageWeekendVisits: 25.0,
      lastWeekends: [
        WeekendDayStats(
          date: DateTime(2024, 1, 5),
          dayName: 'Viernes',
          visitCount: 20,
        ),
        WeekendDayStats(
          date: DateTime(2024, 1, 6),
          dayName: 'Sábado',
          visitCount: 30,
        ),
      ],
    ),
    unusedQrGuests: [
      GuestFrequency(
        guestId: 'guest-1',
        name: 'Guest 1',
        dni: '12345678',
        visitCount: 0,
        lastVisit: DateTime(2024, 1, 1),
      ),
    ],
    frequentWeekendGuests: [
      GuestFrequency(
        guestId: 'guest-2',
        name: 'Guest 2',
        dni: '87654321',
        visitCount: 10,
        lastVisit: DateTime(2024, 1, 10),
      ),
    ],
  );

  setUp(() {
    mockRepository = MockStatisticsRepository();
    cubit = StatisticsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('StatisticsCubit', () {
    test('estado inicial debe ser StatisticsInitial', () {
      expect(cubit.state, const StatisticsInitial());
    });

    blocTest<StatisticsCubit, StatisticsState>(
      'emite [Loading, Loaded] cuando loadStatistics tiene éxito',
      build: () {
        when(() => mockRepository.getStatistics())
            .thenAnswer((_) async => Right(testStatistics));
        return cubit;
      },
      act: (cubit) => cubit.loadStatistics(),
      expect: () => [
        const StatisticsLoading(),
        StatisticsLoaded(testStatistics),
      ],
      verify: (_) {
        verify(() => mockRepository.getStatistics()).called(1);
      },
    );

    blocTest<StatisticsCubit, StatisticsState>(
      'emite [Loading, Error] cuando loadStatistics falla',
      build: () {
        when(() => mockRepository.getStatistics()).thenAnswer(
          (_) async => const Left(DatabaseFailure('Error de conexión')),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadStatistics(),
      expect: () => [
        const StatisticsLoading(),
        const StatisticsError('Error de conexión'),
      ],
    );

    blocTest<StatisticsCubit, StatisticsState>(
      'emite [Loading, Error] con código cuando el repositorio retorna failure con código',
      build: () {
        when(() => mockRepository.getStatistics()).thenAnswer(
          (_) async => const Left(
            DatabaseFailure('No encontrado', code: 'NOT_FOUND'),
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadStatistics(),
      expect: () => [
        const StatisticsLoading(),
        const StatisticsError('No encontrado', code: 'NOT_FOUND'),
      ],
    );

    blocTest<StatisticsCubit, StatisticsState>(
      'refresh() es equivalente a loadStatistics()',
      build: () {
        when(() => mockRepository.getStatistics())
            .thenAnswer((_) async => Right(testStatistics));
        return cubit;
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        const StatisticsLoading(),
        StatisticsLoaded(testStatistics),
      ],
    );

    blocTest<StatisticsCubit, StatisticsState>(
      'puede recargar después de un error',
      build: () {
        var callCount = 0;
        when(() => mockRepository.getStatistics()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const Left(NetworkFailure('Sin conexión'));
          }
          return Right(testStatistics);
        });
        return cubit;
      },
      act: (cubit) async {
        await cubit.loadStatistics();
        await cubit.loadStatistics();
      },
      expect: () => [
        const StatisticsLoading(),
        const StatisticsError('Sin conexión', code: 'NETWORK_ERROR'),
        const StatisticsLoading(),
        StatisticsLoaded(testStatistics),
      ],
    );
  });

  group('StatisticsState', () {
    test('StatisticsInitial tiene props vacías', () {
      const state = StatisticsInitial();
      expect(state.props, isEmpty);
    });

    test('StatisticsLoading incluye message en props', () {
      const state = StatisticsLoading(message: 'Cargando...');
      expect(state.props, ['Cargando...']);
    });

    test('StatisticsLoading usa mensaje por defecto', () {
      const state = StatisticsLoading();
      expect(state.message, 'Cargando estadísticas...');
    });

    test('StatisticsLoaded incluye statistics en props', () {
      final state = StatisticsLoaded(testStatistics);
      expect(state.props, [testStatistics]);
    });

    test('StatisticsError incluye message y code en props', () {
      const state = StatisticsError('Error', code: 'ERR_001');
      expect(state.props, ['Error', 'ERR_001']);
    });

    test('StatisticsError permite code null', () {
      const state = StatisticsError('Error');
      expect(state.code, isNull);
      expect(state.props, ['Error', null]);
    });

    test('dos StatisticsError con mismos datos son iguales', () {
      const state1 = StatisticsError('Error', code: 'ERR');
      const state2 = StatisticsError('Error', code: 'ERR');
      expect(state1, equals(state2));
    });
  });
}
