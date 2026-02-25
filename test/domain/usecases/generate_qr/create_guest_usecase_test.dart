import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/domain/usecases/generate_qr/create_guest_usecase.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

void main() {
  late CreateGuestUseCase useCase;
  late MockGuestRepository mockRepository;

  final testGuest = GuestModel(
    id: '',
    name: 'Test Guest',
    dni: '12345678',
    qrCode: 'COSMO-ABC12345',
    createdBy: 'creator-id',
    createdByName: 'Creator Name',
    createdAt: DateTime.now(),
    isActive: true,
    totalVisits: 0,
  );

  setUp(() {
    mockRepository = MockGuestRepository();
    useCase = CreateGuestUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(testGuest);
  });

  group('CreateGuestUseCase', () {
    test('debe crear guest y retornar el ID generado', () async {
      // Arrange
      when(() => mockRepository.create(any()))
          .thenAnswer((_) async => const Right('new-guest-id'));

      // Act
      final result = await useCase(CreateGuestParams(guest: testGuest));

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (id) => expect(id, equals('new-guest-id')),
      );
      verify(() => mockRepository.create(any())).called(1);
    });

    test('debe retornar Failure cuando el repositorio falla', () async {
      // Arrange
      when(() => mockRepository.create(any()))
          .thenAnswer((_) async => const Left(DatabaseFailure('Error de DB')));

      // Act
      final result = await useCase(CreateGuestParams(guest: testGuest));

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Debería haber fallado'),
      );
    });

    test('debe pasar el guest correcto al repositorio', () async {
      // Arrange
      when(() => mockRepository.create(any()))
          .thenAnswer((_) async => const Right('guest-id'));

      // Act
      await useCase(CreateGuestParams(guest: testGuest));

      // Assert
      final captured = verify(() => mockRepository.create(captureAny())).captured;
      final capturedGuest = captured.first as GuestModel;
      expect(capturedGuest.name, equals('Test Guest'));
      expect(capturedGuest.dni, equals('12345678'));
    });

    test('CreateGuestParams debe ser equatable', () {
      final params1 = CreateGuestParams(guest: testGuest);
      final params2 = CreateGuestParams(guest: testGuest);
      final differentGuest = testGuest.copyWith(dni: '87654321');
      final params3 = CreateGuestParams(guest: differentGuest);

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}
