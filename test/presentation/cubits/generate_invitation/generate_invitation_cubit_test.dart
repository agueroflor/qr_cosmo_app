import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/data/models/models.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/presentation/presentation.dart';

class MockInvitationRepository extends Mock implements InvitationRepository {}

class MockGenerateQrCodeUseCase extends Mock implements GenerateQrCodeUseCase {}

class FakeGenerateQrCodeParams extends Fake implements GenerateQrCodeParams {}

class FakeGuestModel extends Fake implements GuestModel {}

void main() {
  late GenerateInvitationCubit cubit;
  late MockInvitationRepository mockInvitationRepository;
  late MockGenerateQrCodeUseCase mockGenerateQrCodeUseCase;

  setUpAll(() {
    registerFallbackValue(FakeGenerateQrCodeParams());
    registerFallbackValue(FakeGuestModel());
  });

  setUp(() {
    mockInvitationRepository = MockInvitationRepository();
    mockGenerateQrCodeUseCase = MockGenerateQrCodeUseCase();
    cubit = GenerateInvitationCubit(
      mockInvitationRepository,
      mockGenerateQrCodeUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('GenerateInvitationCubit', () {
    test('estado inicial debe ser GenerateInvitationInitial', () {
      expect(cubit.state, const GenerateInvitationInitial());
    });

    blocTest<GenerateInvitationCubit, GenerateInvitationState>(
      'emite [Loading, Success] cuando generateInvitation tiene éxito completo',
      build: () {
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Right('COSMO-INV12345'));
        when(() => mockInvitationRepository.create(any()))
            .thenAnswer((_) async => const Right('invitation-id-123'));
        return cubit;
      },
      act: (cubit) => cubit.generateInvitation(
        name: 'Invitación Viernes',
        maxUses: 5,
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2024, 12, 27), // Viernes
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateInvitationLoading(),
        isA<GenerateInvitationSuccess>(),
      ],
      verify: (cubit) {
        final state = cubit.state as GenerateInvitationSuccess;
        expect(state.invitation.name, 'Invitación Viernes');
        expect(state.invitation.isInvitation, true);
        expect(state.invitation.maxUses, 5);
        expect(state.invitation.validityType, InvitationValidityType.operationalDay);
        expect(state.invitation.validForDate, DateTime(2024, 12, 27));
        expect(state.invitation.createdByName, 'Admin');
        expect(state.invitation.ownerId, 'user-1');
        expect(state.invitation.isActive, true);
        expect(state.invitation.totalVisits, 0);
        expect(state.qrCode, 'COSMO-INV12345');
      },
    );

    blocTest<GenerateInvitationCubit, GenerateInvitationState>(
      'emite [Loading, Error] cuando la generación de QR falla',
      build: () {
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Left(UnexpectedFailure('QR error')));
        return cubit;
      },
      act: (cubit) => cubit.generateInvitation(
        name: 'Invitación Viernes',
        maxUses: 5,
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2024, 12, 27), // Viernes
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateInvitationLoading(),
        const GenerateInvitationError('Error al generar el código QR'),
      ],
      verify: (_) {
        verifyNever(() => mockInvitationRepository.create(any()));
      },
    );

    blocTest<GenerateInvitationCubit, GenerateInvitationState>(
      'emite [Loading, Error] cuando la creación de la invitación falla',
      build: () {
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Right('COSMO-INV12345'));
        when(() => mockInvitationRepository.create(any())).thenAnswer(
          (_) async => const Left(DatabaseFailure('Error de base de datos')),
        );
        return cubit;
      },
      act: (cubit) => cubit.generateInvitation(
        name: 'Invitación Viernes',
        maxUses: 5,
        validityType: InvitationValidityType.operationalDay,
        validForDate: DateTime(2024, 12, 27), // Viernes
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateInvitationLoading(),
        const GenerateInvitationError('Error al guardar: Error de base de datos'),
      ],
    );

    blocTest<GenerateInvitationCubit, GenerateInvitationState>(
      'emite [Loading, Error] cuando el repositorio retorna NetworkFailure',
      build: () {
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Right('COSMO-INV12345'));
        when(() => mockInvitationRepository.create(any())).thenAnswer(
          (_) async => const Left(NetworkFailure('Sin conexión')),
        );
        return cubit;
      },
      act: (cubit) => cubit.generateInvitation(
        name: 'Invitación',
        maxUses: 3,
        validityType: InvitationValidityType.unlimited,
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateInvitationLoading(),
        const GenerateInvitationError('Error al guardar: Sin conexión'),
      ],
    );

    blocTest<GenerateInvitationCubit, GenerateInvitationState>(
      'la invitación generada tiene dni con formato INV-{id}',
      build: () {
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Right('COSMO-INV99999'));
        when(() => mockInvitationRepository.create(any()))
            .thenAnswer((_) async => const Right('inv-id'));
        return cubit;
      },
      act: (cubit) => cubit.generateInvitation(
        name: 'Test',
        maxUses: 10,
        validityType: InvitationValidityType.expirationDate,
        validForDate: DateTime(2024, 6, 15, 23, 59, 59),
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateInvitationLoading(),
        isA<GenerateInvitationSuccess>(),
      ],
      verify: (cubit) {
        final state = cubit.state as GenerateInvitationSuccess;
        expect(state.invitation.dni, startsWith('INV-'));
        expect(state.invitation.isInvitation, true);
        expect(state.invitation.maxUses, 10);
      },
    );

    blocTest<GenerateInvitationCubit, GenerateInvitationState>(
      'el nombre se trimea correctamente',
      build: () {
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Right('COSMO-TRIM1234'));
        when(() => mockInvitationRepository.create(any()))
            .thenAnswer((_) async => const Right('inv-id'));
        return cubit;
      },
      act: (cubit) => cubit.generateInvitation(
        name: '  Invitación con espacios  ',
        maxUses: 2,
        validityType: InvitationValidityType.unlimited,
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateInvitationLoading(),
        isA<GenerateInvitationSuccess>(),
      ],
      verify: (cubit) {
        final state = cubit.state as GenerateInvitationSuccess;
        expect(state.invitation.name, 'Invitación con espacios');
      },
    );

    blocTest<GenerateInvitationCubit, GenerateInvitationState>(
      'resetForm vuelve a GenerateInvitationInitial desde Success',
      build: () => cubit,
      seed: () => GenerateInvitationSuccess(
        invitation: GuestModel(
          id: '1',
          name: 'Test',
          dni: 'INV-1',
          qrCode: 'COSMO-TEST1234',
          createdBy: 'u1',
          createdByName: 'Admin',
          createdAt: DateTime(2024, 1, 1),
          isActive: true,
          totalVisits: 0,
          isInvitation: true,
          maxUses: 5,
          validUntil: DateTime(2024, 12, 31),
        ),
        qrCode: 'COSMO-TEST1234',
      ),
      act: (cubit) => cubit.resetForm(),
      expect: () => [const GenerateInvitationInitial()],
    );

    blocTest<GenerateInvitationCubit, GenerateInvitationState>(
      'resetForm vuelve a GenerateInvitationInitial desde Error',
      build: () => cubit,
      seed: () => const GenerateInvitationError('Error previo'),
      act: (cubit) => cubit.resetForm(),
      expect: () => [const GenerateInvitationInitial()],
    );

    blocTest<GenerateInvitationCubit, GenerateInvitationState>(
      'pasa el repositorio create con el GuestModel correcto',
      build: () {
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Right('COSMO-VERIFY1'));
        when(() => mockInvitationRepository.create(any()))
            .thenAnswer((_) async => const Right('id'));
        return cubit;
      },
      act: (cubit) => cubit.generateInvitation(
        name: 'Verificación',
        maxUses: 7,
        validityType: InvitationValidityType.expirationDate,
        validForDate: DateTime(2024, 6, 15, 23, 59, 59),
        userId: 'user-99',
        userName: 'Operador',
      ),
      verify: (_) {
        final captured = verify(
          () => mockInvitationRepository.create(captureAny()),
        ).captured;
        final guest = captured.first as GuestModel;
        expect(guest.name, 'Verificación');
        expect(guest.maxUses, 7);
        expect(guest.validityType, InvitationValidityType.expirationDate);
        expect(guest.validForDate, DateTime(2024, 6, 15, 23, 59, 59));
        expect(guest.createdBy, 'user-99');
        expect(guest.createdByName, 'Operador');
        expect(guest.ownerId, 'user-99');
        expect(guest.isInvitation, true);
        expect(guest.qrCode, 'COSMO-VERIFY1');
      },
    );
  });

  group('GenerateInvitationState', () {
    test('GenerateInvitationInitial tiene props vacías', () {
      const state = GenerateInvitationInitial();
      expect(state.props, isEmpty);
    });

    test('GenerateInvitationLoading tiene props vacías', () {
      const state = GenerateInvitationLoading();
      expect(state.props, isEmpty);
    });

    test('GenerateInvitationSuccess incluye invitation y qrCode en props', () {
      final state = GenerateInvitationSuccess(
        invitation: GuestModel(
          id: '1',
          name: 'Test',
          dni: 'INV-1',
          qrCode: 'QR',
          createdBy: 'u',
          createdByName: 'U',
          createdAt: DateTime(2024, 1, 1),
          isActive: true,
          totalVisits: 0,
          isInvitation: true,
          maxUses: 5,
        ),
        qrCode: 'QR-CODE',
      );
      expect(state.props.length, 2);
    });

    test('GenerateInvitationError incluye message en props', () {
      const state = GenerateInvitationError('Error');
      expect(state.props, ['Error']);
    });
  });
}
