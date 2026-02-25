import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/domain/repositories/visit_repository.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/process_guest_entry_usecase.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/validate_invitation_validity_usecase.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import 'package:qr_cosmo_app/data/models/visit_model.dart';

class MockGuestRepository extends Mock implements GuestRepository {}
class MockVisitRepository extends Mock implements VisitRepository {}
class MockValidateInvitationValidityUseCase extends Mock
    implements ValidateInvitationValidityUseCase {}

void main() {
  late ProcessGuestEntryUseCase useCase;
  late MockGuestRepository mockGuestRepository;
  late MockVisitRepository mockVisitRepository;
  late MockValidateInvitationValidityUseCase mockValidateInvitationValidity;

  final testGuest = GuestModel(
    id: 'guest-id',
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
    mockGuestRepository = MockGuestRepository();
    mockVisitRepository = MockVisitRepository();
    mockValidateInvitationValidity = MockValidateInvitationValidityUseCase();

    // Default: validation always passes
    when(() => mockValidateInvitationValidity(any()))
        .thenAnswer((_) async => const Right(null));

    useCase = ProcessGuestEntryUseCase(
      mockGuestRepository,
      mockVisitRepository,
      mockValidateInvitationValidity,
    );
  });

  setUpAll(() {
    registerFallbackValue(ValidateInvitationValidityParams(
      guest: GuestModel(
        id: '',
        name: '',
        dni: '',
        qrCode: '',
        createdBy: '',
        createdByName: '',
        createdAt: DateTime(2024, 1, 1),
      ),
      currentDateTime: DateTime(2024, 1, 1),
    ));
    registerFallbackValue(VisitModel(
      id: '',
      guestId: '',
      guestName: '',
      dni: '',
      scannedBy: '',
      scannedByName: '',
      scannedAt: DateTime.now(),
      isFirstTime: false,
    ));
    registerFallbackValue(<VisitModel>[]);
  });

  group('ProcessGuestEntryUseCase', () {
    test('debe crear visita y actualizar contador exitosamente', () async {
      // Arrange
      when(() => mockVisitRepository.create(any()))
          .thenAnswer((_) async => const Right('visit-id'));
      when(() => mockGuestRepository.markAsUsed('guest-id', count: 1))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(ProcessGuestEntryParams(
        guest: testGuest,
        count: 1,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      ));

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => mockVisitRepository.create(any())).called(1);
      verify(() => mockGuestRepository.markAsUsed('guest-id', count: 1)).called(1);
    });

    test('debe crear múltiples visitas cuando count > 1', () async {
      // Arrange
      when(() => mockVisitRepository.createBatch(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => mockGuestRepository.markAsUsed('guest-id', count: 3))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(ProcessGuestEntryParams(
        guest: testGuest,
        count: 3,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      ));

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => mockVisitRepository.createBatch(any())).called(1);
      verify(() => mockGuestRepository.markAsUsed('guest-id', count: 3)).called(1);
    });

    test('debe fallar si el guest está inactivo', () async {
      // Arrange
      final inactiveGuest = testGuest.copyWith(isActive: false);

      // Act
      final result = await useCase(ProcessGuestEntryParams(
        guest: inactiveGuest,
        count: 1,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      ));

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<QrFailure>());
          expect((failure as QrFailure).code, equals('QR_DEACTIVATED'));
        },
        (_) => fail('Debería haber fallado'),
      );
      verifyNever(() => mockVisitRepository.create(any()));
      verifyNever(() => mockGuestRepository.markAsUsed(any(), count: any(named: 'count')));
    });

    test('debe fallar si la invitación alcanzó el límite de usos', () async {
      // Arrange
      final maxUsedInvitation = testGuest.copyWith(
        isInvitation: true,
        maxUses: 2,
        totalVisits: 2, // Ya usó todos los usos disponibles
      );

      // Mock validity to return max uses reached
      when(() => mockValidateInvitationValidity(any()))
          .thenAnswer((_) async => Left(QrFailure.maxUsesReached(2)));

      // Act
      final result = await useCase(ProcessGuestEntryParams(
        guest: maxUsedInvitation,
        count: 1,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      ));

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<QrFailure>());
          expect((failure as QrFailure).code, equals('MAX_USES_REACHED'));
        },
        (_) => fail('Debería haber fallado'),
      );
    });

    test('debe permitir entrada si la invitación tiene usos disponibles', () async {
      // Arrange
      final validInvitation = testGuest.copyWith(
        isInvitation: true,
        maxUses: 5,
        totalVisits: 2, // Aún tiene 3 usos disponibles
      );
      when(() => mockVisitRepository.create(any()))
          .thenAnswer((_) async => const Right('visit-id'));
      when(() => mockGuestRepository.markAsUsed(validInvitation.id, count: 1))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await useCase(ProcessGuestEntryParams(
        guest: validInvitation,
        count: 1,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      ));

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('debe fallar si la creación de visita falla', () async {
      // Arrange
      when(() => mockVisitRepository.create(any()))
          .thenAnswer((_) async => const Left(DatabaseFailure('Error de DB')));

      // Act
      final result = await useCase(ProcessGuestEntryParams(
        guest: testGuest,
        count: 1,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      ));

      // Assert
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockGuestRepository.markAsUsed(any(), count: any(named: 'count')));
    });

    test('debe fallar si la actualización del guest falla', () async {
      // Arrange
      when(() => mockVisitRepository.create(any()))
          .thenAnswer((_) async => const Right('visit-id'));
      when(() => mockGuestRepository.markAsUsed('guest-id', count: 1))
          .thenAnswer((_) async => const Left(DatabaseFailure('Error de DB')));

      // Act
      final result = await useCase(ProcessGuestEntryParams(
        guest: testGuest,
        count: 1,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      ));

      // Assert
      expect(result.isLeft(), isTrue);
    });

    test('ProcessGuestEntryParams debe ser equatable', () {
      final params1 = ProcessGuestEntryParams(
        guest: testGuest,
        count: 1,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      );
      final params2 = ProcessGuestEntryParams(
        guest: testGuest,
        count: 1,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      );
      final params3 = ProcessGuestEntryParams(
        guest: testGuest,
        count: 2,
        scannerId: 'scanner-id',
        scannerName: 'Scanner Name',
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });
  });
}
