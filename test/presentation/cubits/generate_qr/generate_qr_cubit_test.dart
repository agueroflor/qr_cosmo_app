import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_cosmo_app/data/models/models.dart';
import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/presentation/presentation.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

class MockCreateGuestUseCase extends Mock implements CreateGuestUseCase {}

class MockGenerateQrCodeUseCase extends Mock implements GenerateQrCodeUseCase {}

class FakeCreateGuestParams extends Fake implements CreateGuestParams {}

class FakeGenerateQrCodeParams extends Fake implements GenerateQrCodeParams {}

void main() {
  late GenerateQrCubit cubit;
  late MockGuestRepository mockGuestRepository;
  late MockCreateGuestUseCase mockCreateGuestUseCase;
  late MockGenerateQrCodeUseCase mockGenerateQrCodeUseCase;

  setUpAll(() {
    registerFallbackValue(FakeCreateGuestParams());
    registerFallbackValue(FakeGenerateQrCodeParams());
  });

  setUp(() {
    mockGuestRepository = MockGuestRepository();
    mockCreateGuestUseCase = MockCreateGuestUseCase();
    mockGenerateQrCodeUseCase = MockGenerateQrCodeUseCase();
    cubit = GenerateQrCubit(
      mockGuestRepository,
      mockCreateGuestUseCase,
      mockGenerateQrCodeUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('GenerateQrCubit', () {
    test('estado inicial debe ser GenerateQrInitial', () {
      expect(cubit.state, const GenerateQrInitial());
    });

    blocTest<GenerateQrCubit, GenerateQrState>(
      'emite [Loading, Success] cuando generateQr tiene éxito completo',
      build: () {
        // DNI no existe
        when(() => mockGuestRepository.getByDni(any()))
            .thenAnswer((_) async => const Right(null));
        // QR generado exitosamente
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Right('COSMO-ABC12345'));
        // Guest creado exitosamente
        when(() => mockCreateGuestUseCase(any()))
            .thenAnswer((_) async => const Right('guest-id-123'));
        return cubit;
      },
      act: (cubit) => cubit.generateQr(
        name: 'Juan Pérez',
        dni: '12345678',
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateQrLoading(),
        isA<GenerateQrSuccess>(),
      ],
      verify: (cubit) {
        final state = cubit.state as GenerateQrSuccess;
        expect(state.guest.name, 'Juan Pérez');
        expect(state.guest.dni, '12345678');
        expect(state.qrCode, 'COSMO-ABC12345');
      },
    );

    blocTest<GenerateQrCubit, GenerateQrState>(
      'emite [Loading, Error] cuando el DNI ya existe con guest activo',
      build: () {
        final existingGuest = GuestModel(
          id: 'existing-1',
          name: 'Existente',
          dni: '12345678',
          qrCode: 'COSMO-EXISTING1',
          createdBy: 'user-1',
          createdByName: 'Admin',
          createdAt: DateTime(2024, 1, 1),
          isActive: true,
          totalVisits: 0,
        );
        when(() => mockGuestRepository.getByDni(any()))
            .thenAnswer((_) async => Right(existingGuest));
        return cubit;
      },
      act: (cubit) => cubit.generateQr(
        name: 'Juan',
        dni: '12345678',
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateQrLoading(),
        const GenerateQrError('Ya existe un invitado activo con este DNI'),
      ],
      verify: (_) {
        verifyNever(() => mockGenerateQrCodeUseCase(any()));
        verifyNever(() => mockCreateGuestUseCase(any()));
      },
    );

    blocTest<GenerateQrCubit, GenerateQrState>(
      'permite generar si existe guest inactivo con mismo DNI',
      build: () {
        final inactiveGuest = GuestModel(
          id: 'existing-1',
          name: 'Existente',
          dni: '12345678',
          qrCode: 'COSMO-EXISTING1',
          createdBy: 'user-1',
          createdByName: 'Admin',
          createdAt: DateTime(2024, 1, 1),
          isActive: false,
          totalVisits: 0,
        );
        when(() => mockGuestRepository.getByDni(any()))
            .thenAnswer((_) async => Right(inactiveGuest));
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Right('COSMO-NEW12345'));
        when(() => mockCreateGuestUseCase(any()))
            .thenAnswer((_) async => const Right('new-guest-id'));
        return cubit;
      },
      act: (cubit) => cubit.generateQr(
        name: 'Juan',
        dni: '12345678',
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateQrLoading(),
        isA<GenerateQrSuccess>(),
      ],
    );

    blocTest<GenerateQrCubit, GenerateQrState>(
      'emite [Loading, Error] cuando la generación de QR falla',
      build: () {
        when(() => mockGuestRepository.getByDni(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Left(UnexpectedFailure('QR error')));
        return cubit;
      },
      act: (cubit) => cubit.generateQr(
        name: 'Juan',
        dni: '12345678',
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateQrLoading(),
        const GenerateQrError('Error al generar el código QR'),
      ],
      verify: (_) {
        verifyNever(() => mockCreateGuestUseCase(any()));
      },
    );

    blocTest<GenerateQrCubit, GenerateQrState>(
      'emite [Loading, Error] cuando la creación del guest falla',
      build: () {
        when(() => mockGuestRepository.getByDni(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockGenerateQrCodeUseCase(any()))
            .thenAnswer((_) async => const Right('COSMO-ABC12345'));
        when(() => mockCreateGuestUseCase(any())).thenAnswer(
          (_) async => const Left(DatabaseFailure('Error de base de datos')),
        );
        return cubit;
      },
      act: (cubit) => cubit.generateQr(
        name: 'Juan',
        dni: '12345678',
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateQrLoading(),
        const GenerateQrError('Error al guardar: Error de base de datos'),
      ],
    );

    blocTest<GenerateQrCubit, GenerateQrState>(
      'emite [Loading, Error] cuando getByDni falla',
      build: () {
        when(() => mockGuestRepository.getByDni(any())).thenAnswer(
          (_) async => const Left(NetworkFailure('Sin conexión')),
        );
        return cubit;
      },
      act: (cubit) => cubit.generateQr(
        name: 'Juan',
        dni: '12345678',
        userId: 'user-1',
        userName: 'Admin',
      ),
      expect: () => [
        const GenerateQrLoading(),
        const GenerateQrError('Sin conexión'),
      ],
    );

    blocTest<GenerateQrCubit, GenerateQrState>(
      'resetForm vuelve a GenerateQrInitial desde Success',
      build: () => cubit,
      seed: () => GenerateQrSuccess(
        guest: GuestModel(
          id: '1',
          name: 'Test',
          dni: '12345678',
          qrCode: 'COSMO-TEST1234',
          createdBy: 'u1',
          createdByName: 'Admin',
          createdAt: DateTime(2024, 1, 1),
          isActive: true,
          totalVisits: 0,
        ),
        qrCode: 'COSMO-TEST1234',
      ),
      act: (cubit) => cubit.resetForm(),
      expect: () => [const GenerateQrInitial()],
    );

    blocTest<GenerateQrCubit, GenerateQrState>(
      'resetForm vuelve a GenerateQrInitial desde Error',
      build: () => cubit,
      seed: () => const GenerateQrError('Error previo'),
      act: (cubit) => cubit.resetForm(),
      expect: () => [const GenerateQrInitial()],
    );
  });

  group('GenerateQrState', () {
    test('GenerateQrInitial tiene props vacías', () {
      const state = GenerateQrInitial();
      expect(state.props, isEmpty);
    });

    test('GenerateQrLoading tiene props vacías', () {
      const state = GenerateQrLoading();
      expect(state.props, isEmpty);
    });

    test('GenerateQrSuccess incluye guest y qrCode en props', () {
      final state = GenerateQrSuccess(
        guest: GuestModel(
          id: '1',
          name: 'Test',
          dni: '123',
          qrCode: 'QR',
          createdBy: 'u',
          createdByName: 'U',
          createdAt: DateTime(2024, 1, 1),
          isActive: true,
          totalVisits: 0,
        ),
        qrCode: 'QR-CODE',
      );
      expect(state.props.length, 2);
    });

    test('GenerateQrError incluye message en props', () {
      const state = GenerateQrError('Error');
      expect(state.props, ['Error']);
    });
  });
}
