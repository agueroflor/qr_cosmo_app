import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/repositories/visit_repository.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/get_last_scan_count_usecase.dart';
import 'package:qr_cosmo_app/data/models/visit_model.dart';

class MockVisitRepository extends Mock implements VisitRepository {}

void main() {
  late GetLastScanCountUseCase useCase;
  late MockVisitRepository mockRepository;

  setUp(() {
    mockRepository = MockVisitRepository();
    useCase = GetLastScanCountUseCase(mockRepository);
  });

  VisitModel createVisit({required DateTime scannedAt}) {
    return VisitModel(
      id: 'visit-id',
      guestId: 'guest-id',
      guestName: 'Test Guest',
      dni: '12345678',
      scannedBy: 'scanner-id',
      scannedByName: 'Scanner',
      scannedAt: scannedAt,
      isFirstTime: false,
    );
  }

  group('GetLastScanCountUseCase', () {
    test('debe retornar conteo de visitas recientes (< 3 minutos)', () async {
      // Arrange
      final now = DateTime.now();
      final recentVisits = [
        createVisit(scannedAt: now.subtract(const Duration(seconds: 30))),
        createVisit(scannedAt: now.subtract(const Duration(minutes: 1))),
        createVisit(scannedAt: now.subtract(const Duration(minutes: 2))),
      ];

      when(() => mockRepository.getLastVisits('guest-id', limit: 100))
          .thenAnswer((_) async => Right(recentVisits));

      // Act
      final result = await useCase(
        const GetLastScanCountParams(guestId: 'guest-id'),
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (count) => expect(count, equals(3)),
      );
    });

    test('debe excluir visitas antiguas (> 3 minutos)', () async {
      // Arrange
      final now = DateTime.now();
      final mixedVisits = [
        createVisit(scannedAt: now.subtract(const Duration(minutes: 1))), // Reciente
        createVisit(scannedAt: now.subtract(const Duration(minutes: 5))), // Antigua
        createVisit(scannedAt: now.subtract(const Duration(minutes: 10))), // Antigua
      ];

      when(() => mockRepository.getLastVisits('guest-id', limit: 100))
          .thenAnswer((_) async => Right(mixedVisits));

      // Act
      final result = await useCase(
        const GetLastScanCountParams(guestId: 'guest-id'),
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (count) => expect(count, equals(1)), // Solo 1 reciente
      );
    });

    test('debe retornar 0 si no hay visitas recientes', () async {
      // Arrange
      final now = DateTime.now();
      final oldVisits = [
        createVisit(scannedAt: now.subtract(const Duration(minutes: 10))),
        createVisit(scannedAt: now.subtract(const Duration(hours: 1))),
      ];

      when(() => mockRepository.getLastVisits('guest-id', limit: 100))
          .thenAnswer((_) async => Right(oldVisits));

      // Act
      final result = await useCase(
        const GetLastScanCountParams(guestId: 'guest-id'),
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (count) => expect(count, equals(0)),
      );
    });

    test('debe retornar 0 si no hay visitas', () async {
      // Arrange
      when(() => mockRepository.getLastVisits('guest-id', limit: 100))
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(
        const GetLastScanCountParams(guestId: 'guest-id'),
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (count) => expect(count, equals(0)),
      );
    });

    test('debe retornar Failure cuando el repositorio falla', () async {
      // Arrange
      when(() => mockRepository.getLastVisits(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Left(DatabaseFailure('Error de DB')));

      // Act
      final result = await useCase(
        const GetLastScanCountParams(guestId: 'guest-id'),
      );

      // Assert
      expect(result.isLeft(), isTrue);
    });

    test('GetLastScanCountParams debe ser equatable', () {
      const params1 = GetLastScanCountParams(guestId: 'guest-id');
      const params2 = GetLastScanCountParams(guestId: 'guest-id');
      const params3 = GetLastScanCountParams(guestId: 'other-id');

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}
