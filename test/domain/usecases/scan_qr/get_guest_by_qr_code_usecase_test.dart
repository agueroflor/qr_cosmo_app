import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/get_guest_by_qr_code_usecase.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

void main() {
  late GetGuestByQrCodeUseCase useCase;
  late MockGuestRepository mockRepository;

  final testGuest = GuestModel(
    id: 'test-id',
    name: 'Test Guest',
    dni: '12345678',
    qrCode: 'COSMO-ABC12345',
    createdBy: 'creator-id',
    createdByName: 'Creator',
    createdAt: DateTime.now(),
    isActive: true,
    totalVisits: 0,
  );

  setUp(() {
    mockRepository = MockGuestRepository();
    useCase = GetGuestByQrCodeUseCase(mockRepository);
  });

  group('GetGuestByQrCodeUseCase', () {
    test('debe retornar GuestModel cuando el QR existe', () async {
      // Arrange
      when(() => mockRepository.getByQrCode('COSMO-ABC12345'))
          .thenAnswer((_) async => Right(testGuest));

      // Act
      final result = await useCase(
        const GetGuestByQrCodeParams(qrCode: 'COSMO-ABC12345'),
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (guest) {
          expect(guest, isNotNull);
          expect(guest!.qrCode, equals('COSMO-ABC12345'));
          expect(guest.name, equals('Test Guest'));
        },
      );
      verify(() => mockRepository.getByQrCode('COSMO-ABC12345')).called(1);
    });

    test('debe retornar null cuando el QR no existe', () async {
      // Arrange
      when(() => mockRepository.getByQrCode('COSMO-NOTFOUND'))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(
        const GetGuestByQrCodeParams(qrCode: 'COSMO-NOTFOUND'),
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('No debería fallar'),
        (guest) => expect(guest, isNull),
      );
    });

    test('debe retornar Failure cuando el repositorio falla', () async {
      // Arrange
      when(() => mockRepository.getByQrCode(any()))
          .thenAnswer((_) async => const Left(DatabaseFailure('Error de DB')));

      // Act
      final result = await useCase(
        const GetGuestByQrCodeParams(qrCode: 'COSMO-ABC12345'),
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Debería haber fallado'),
      );
    });

    test('GetGuestByQrCodeParams debe ser equatable', () {
      const params1 = GetGuestByQrCodeParams(qrCode: 'COSMO-ABC12345');
      const params2 = GetGuestByQrCodeParams(qrCode: 'COSMO-ABC12345');
      const params3 = GetGuestByQrCodeParams(qrCode: 'COSMO-DIFFERENT');

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}
