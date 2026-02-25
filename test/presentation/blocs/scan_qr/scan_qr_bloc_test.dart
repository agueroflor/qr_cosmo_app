import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/get_guest_by_qr_code_usecase.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/get_last_scan_count_usecase.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/process_guest_entry_usecase.dart';
import 'package:qr_cosmo_app/domain/entities/invitation_validity_type.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/validate_invitation_validity_usecase.dart';
import 'package:qr_cosmo_app/domain/usecases/scan_qr/validate_qr_code_usecase.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import 'package:qr_cosmo_app/core/services/scan_observer_service.dart';
import 'package:qr_cosmo_app/presentation/blocs/scan_qr/scan_qr_bloc.dart';

class MockValidateQrCodeUseCase extends Mock implements ValidateQrCodeUseCase {}

class MockGetGuestByQrCodeUseCase extends Mock
    implements GetGuestByQrCodeUseCase {}

class MockProcessGuestEntryUseCase extends Mock
    implements ProcessGuestEntryUseCase {}

class MockGetLastScanCountUseCase extends Mock
    implements GetLastScanCountUseCase {}

class MockValidateInvitationValidityUseCase extends Mock
    implements ValidateInvitationValidityUseCase {}

class MockScanObserverService extends Mock implements ScanObserverService {}

class FakeValidateQrCodeParams extends Fake implements ValidateQrCodeParams {}

class FakeGetGuestByQrCodeParams extends Fake
    implements GetGuestByQrCodeParams {}

class FakeProcessGuestEntryParams extends Fake
    implements ProcessGuestEntryParams {}

class FakeGetLastScanCountParams extends Fake
    implements GetLastScanCountParams {}

class FakeValidateInvitationValidityParams extends Fake
    implements ValidateInvitationValidityParams {}

class FakeGuestModel extends Fake implements GuestModel {}

void main() {
  late ScanQrBloc bloc;
  late MockValidateQrCodeUseCase mockValidateQrCode;
  late MockGetGuestByQrCodeUseCase mockGetGuestByQrCode;
  late MockProcessGuestEntryUseCase mockProcessGuestEntry;
  late MockGetLastScanCountUseCase mockGetLastScanCount;
  late MockValidateInvitationValidityUseCase mockValidateInvitationValidity;
  late MockScanObserverService mockScanObserver;

  setUpAll(() {
    registerFallbackValue(FakeValidateQrCodeParams());
    registerFallbackValue(FakeGetGuestByQrCodeParams());
    registerFallbackValue(FakeProcessGuestEntryParams());
    registerFallbackValue(FakeGetLastScanCountParams());
    registerFallbackValue(FakeValidateInvitationValidityParams());
    registerFallbackValue(FakeGuestModel());
  });

  setUp(() {
    mockValidateQrCode = MockValidateQrCodeUseCase();
    mockGetGuestByQrCode = MockGetGuestByQrCodeUseCase();
    mockProcessGuestEntry = MockProcessGuestEntryUseCase();
    mockGetLastScanCount = MockGetLastScanCountUseCase();
    mockValidateInvitationValidity = MockValidateInvitationValidityUseCase();
    mockScanObserver = MockScanObserverService();

    // Default stubs para ScanObserver (fire-and-forget)
    when(() => mockScanObserver.onNoInternet(
          qrCode: any(named: 'qrCode'),
          scannedBy: any(named: 'scannedBy'),
          scannedByName: any(named: 'scannedByName'),
        )).thenAnswer((_) async {});
    when(() => mockScanObserver.onInvalidQR(
          qrCode: any(named: 'qrCode'),
          scannedBy: any(named: 'scannedBy'),
          scannedByName: any(named: 'scannedByName'),
          errorMessage: any(named: 'errorMessage'),
        )).thenAnswer((_) async {});
    when(() => mockScanObserver.onInactiveQR(
          qrCode: any(named: 'qrCode'),
          guest: any(named: 'guest'),
          scannedBy: any(named: 'scannedBy'),
          scannedByName: any(named: 'scannedByName'),
        )).thenAnswer((_) async {});
    when(() => mockScanObserver.onAlreadyUsedToday(
          qrCode: any(named: 'qrCode'),
          guest: any(named: 'guest'),
          scannedBy: any(named: 'scannedBy'),
          scannedByName: any(named: 'scannedByName'),
        )).thenAnswer((_) async {});
    when(() => mockScanObserver.onNoRemainingUses(
          qrCode: any(named: 'qrCode'),
          guest: any(named: 'guest'),
          scannedBy: any(named: 'scannedBy'),
          scannedByName: any(named: 'scannedByName'),
        )).thenAnswer((_) async {});
    when(() => mockScanObserver.onAccessGranted(
          qrCode: any(named: 'qrCode'),
          guest: any(named: 'guest'),
          scannedBy: any(named: 'scannedBy'),
          scannedByName: any(named: 'scannedByName'),
          guestCount: any(named: 'guestCount'),
          totalVisitsAfterScan: any(named: 'totalVisitsAfterScan'),
        )).thenAnswer((_) async {});
    when(() => mockScanObserver.onException(
          qrCode: any(named: 'qrCode'),
          scannedBy: any(named: 'scannedBy'),
          scannedByName: any(named: 'scannedByName'),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
          guest: any(named: 'guest'),
        )).thenAnswer((_) async {});

    when(() => mockValidateInvitationValidity(any()))
        .thenAnswer((_) async => const Right(null));

    bloc = ScanQrBloc(
      validateQrCodeUseCase: mockValidateQrCode,
      getGuestByQrCodeUseCase: mockGetGuestByQrCode,
      processGuestEntryUseCase: mockProcessGuestEntry,
      getLastScanCountUseCase: mockGetLastScanCount,
      validateInvitationValidityUseCase: mockValidateInvitationValidity,
      scanObserver: mockScanObserver,
      connectivityChecker: () async => true,
    );
    bloc.setCurrentUser('user-1', 'Admin');
  });

  tearDown(() {
    bloc.close();
  });

  GuestModel _personalGuest({
    bool isActive = true,
    int totalVisits = 0,
    DateTime? lastUsedDate,
    DateTime? lastSuccessfulEntry,
  }) {
    return GuestModel(
      id: 'guest-1',
      name: 'Juan P\u00e9rez',
      dni: '12345678',
      qrCode: 'COSMO-ABC12345',
      createdBy: 'user-1',
      createdByName: 'Admin',
      createdAt: DateTime(2024, 1, 1),
      isActive: isActive,
      totalVisits: totalVisits,
      lastUsedDate: lastUsedDate,
      lastSuccessfulEntry: lastSuccessfulEntry,
    );
  }

  GuestModel _invitationGuest({
    bool isActive = true,
    int totalVisits = 0,
    int maxUses = 5,
    DateTime? lastUsedDate,
    DateTime? validUntil,
  }) {
    return GuestModel(
      id: 'inv-1',
      name: 'Invitaci\u00f3n VIP',
      dni: 'INV-123',
      qrCode: 'COSMO-INV12345',
      createdBy: 'user-1',
      createdByName: 'Creador',
      createdAt: DateTime(2024, 1, 1),
      isActive: isActive,
      totalVisits: totalVisits,
      maxUses: maxUses,
      isInvitation: true,
      lastUsedDate: lastUsedDate,
      validUntil: validUntil ?? DateTime(2024, 12, 31),
    );
  }

  group('ScanQrBloc - Estado inicial', () {
    test('estado inicial debe ser ScanQrIdle', () {
      expect(bloc.state, isA<ScanQrIdle>());
    });
  });

  group('ScanQrBloc - Sin conexi?n', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando no hay conexi?n a internet',
      build: () {
        return ScanQrBloc(
          validateQrCodeUseCase: mockValidateQrCode,
          getGuestByQrCodeUseCase: mockGetGuestByQrCode,
          processGuestEntryUseCase: mockProcessGuestEntry,
          getLastScanCountUseCase: mockGetLastScanCount,
          validateInvitationValidityUseCase: mockValidateInvitationValidity,
          scanObserver: mockScanObserver,
          connectivityChecker: () async => false,
        )..setCurrentUser('user-1', 'Admin');
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-ABC12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.noConnection,
        ),
      ],
    );
  });

  group('ScanQrBloc - QR inv?lido', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando el formato QR es inv?lido',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(false));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('INVALID-QR')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.invalidQr,
        ),
      ],
    );
  });

  group('ScanQrBloc - QR no encontrado', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando el guest no se encuentra',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-ABC12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.qrNotFound,
        ),
      ],
    );
  });

  group('ScanQrBloc - Guest inactivo', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando el guest est? desactivado',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(_personalGuest(isActive: false)));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-ABC12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.qrDeactivated,
        ),
      ],
    );
  });

  group('ScanQrBloc - QR personal exitoso', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Success] para QR personal v?lido',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(_personalGuest()));
        when(() => mockProcessGuestEntry(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-ABC12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrSuccess>()
            .having((s) => s.guestName, 'guestName', 'Juan P\u00e9rez')
            .having(
                (s) => s.accessTypeLabel, 'accessTypeLabel', 'Free Pass / Personal'),
      ],
    );
  });

  group('ScanQrBloc - QR personal ya usado hoy', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando QR personal ya fue usado hoy y no recientemente',
      build: () {
        final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
        final guest = _personalGuest(
          totalVisits: 1,
          lastUsedDate: fiveMinutesAgo,
          lastSuccessfulEntry: fiveMinutesAgo,
        );
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(guest));
        when(() => mockProcessGuestEntry(any()))
            .thenAnswer((_) async => Left(QrFailure.alreadyUsedToday()));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-ABC12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.qrUsedToday,
        ),
      ],
    );
  });

  group('ScanQrBloc - Invitaci?n con usos disponibles', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, InvitationInput] para invitaci?n v?lida',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(_invitationGuest()));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-INV12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrInvitationInput>()
            .having((s) => s.guestName, 'guestName', 'Invitaci\u00f3n VIP')
            .having((s) => s.maxUses, 'maxUses', 5)
            .having((s) => s.remainingUses, 'remainingUses', 5)
            .having((s) => s.guestCount, 'guestCount', 1),
      ],
    );
  });

  group('ScanQrBloc - Invitaci?n sin usos restantes', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando la invitaci?n agot? sus usos',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(_invitationGuest(
                  totalVisits: 5,
                  maxUses: 5,
                )));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-INV12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.maxUsesReached,
        ),
      ],
    );
  });

  group('ScanQrBloc - Invitaci?n re-escaneo reciente', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite maxUsesReached cuando la invitaci?n no tiene usos (aunque fue usada recientemente)',
      build: () {
        final guest = _invitationGuest(
          totalVisits: 5,
          maxUses: 5,
          lastUsedDate: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(guest));
        when(() => mockGetLastScanCount(any()))
            .thenAnswer((_) async => const Right(3));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-INV12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.maxUsesReached,
        ),
      ],
    );
  });

  group('ScanQrBloc - GuestCount events', () {
    final invitationState = const ScanQrInvitationInput(
      guestName: 'Test',
      validUntilFormatted: null,
      createdByName: 'Admin',
      maxUses: 5,
      remainingUses: 3,
      lastUsedDateFormatted: null,
      remainingUsesColor: Colors.green,
      guestCount: 1,
      isConfirming: false,
      guestId: 'inv-1',
      wasUsedRecently: false,
      lastScanCount: 1,
    );

    blocTest<ScanQrBloc, ScanQrState>(
      'GuestCountIncremented incrementa la cantidad',
      build: () => bloc,
      seed: () => invitationState,
      act: (bloc) => bloc.add(const GuestCountIncremented()),
      expect: () => [
        isA<ScanQrInvitationInput>()
            .having((s) => s.guestCount, 'guestCount', 2),
      ],
    );

    blocTest<ScanQrBloc, ScanQrState>(
      'GuestCountDecremented no baja de 1',
      build: () => bloc,
      seed: () => invitationState,
      act: (bloc) => bloc.add(const GuestCountDecremented()),
      expect: () => const <ScanQrState>[],
    );

    blocTest<ScanQrBloc, ScanQrState>(
      'GuestCountDecremented decrementa si guestCount > 1',
      build: () => bloc,
      seed: () => invitationState.copyWith(guestCount: 3),
      act: (bloc) => bloc.add(const GuestCountDecremented()),
      expect: () => [
        isA<ScanQrInvitationInput>()
            .having((s) => s.guestCount, 'guestCount', 2),
      ],
    );

    blocTest<ScanQrBloc, ScanQrState>(
      'GuestCountChanged actualiza la cantidad con clamp',
      build: () => bloc,
      seed: () => invitationState,
      act: (bloc) => bloc.add(const GuestCountChanged(2)),
      expect: () => [
        isA<ScanQrInvitationInput>()
            .having((s) => s.guestCount, 'guestCount', 2),
      ],
    );

    blocTest<ScanQrBloc, ScanQrState>(
      'GuestCountChanged no excede remainingUses',
      build: () => bloc,
      seed: () => invitationState,
      act: (bloc) => bloc.add(const GuestCountChanged(10)),
      expect: () => [
        isA<ScanQrInvitationInput>()
            .having((s) => s.guestCount, 'guestCount', 3),
      ],
    );

    blocTest<ScanQrBloc, ScanQrState>(
      'GuestCountIncremented no excede remainingUses',
      build: () => bloc,
      seed: () => invitationState.copyWith(guestCount: 3),
      act: (bloc) => bloc.add(const GuestCountIncremented()),
      expect: () => const <ScanQrState>[],
    );
  });

  group('ScanQrBloc - ConfirmGuestEntry', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [isConfirming, Success] cuando confirmaci?n es exitosa',
      build: () {
        // Primero necesitamos que el bloc tenga _currentGuest
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(_invitationGuest()));
        when(() => mockProcessGuestEntry(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) async {
        // Primero detectar QR para setear _currentGuest
        bloc.add(const QrCodeDetected('COSMO-INV12345'));
        await Future.delayed(const Duration(milliseconds: 100));
        // Luego confirmar
        bloc.add(const ConfirmGuestEntry());
      },
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrInvitationInput>(),
        isA<ScanQrInvitationInput>()
            .having((s) => s.isConfirming, 'isConfirming', true),
        isA<ScanQrSuccess>()
            .having((s) => s.accessTypeLabel, 'accessTypeLabel', 'Invitaci\u00f3n'),
      ],
    );
  });

  group('ScanQrBloc - ProcessGuestEntry failure', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, InvitationInput, isConfirming, Error] cuando processGuestEntry falla',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(_invitationGuest()));
        when(() => mockProcessGuestEntry(any())).thenAnswer(
          (_) async => const Left(DatabaseFailure('Error de base de datos')),
        );
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const QrCodeDetected('COSMO-INV12345'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const ConfirmGuestEntry());
      },
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrInvitationInput>(),
        isA<ScanQrInvitationInput>()
            .having((s) => s.isConfirming, 'isConfirming', true),
        isA<ScanQrError>(),
      ],
    );
  });

  group('ScanQrBloc - ScanAgainRequested', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'resetea a Idle',
      build: () => bloc,
      seed: () => const ScanQrInvitationInput(
        guestName: 'Test',
        validUntilFormatted: null,
        createdByName: 'Admin',
        maxUses: 5,
        remainingUses: 3,
        lastUsedDateFormatted: null,
        remainingUsesColor: Colors.green,
        guestCount: 1,
        isConfirming: false,
        guestId: 'inv-1',
        wasUsedRecently: false,
        lastScanCount: 1,
      ),
      act: (bloc) => bloc.add(const ScanAgainRequested()),
      expect: () => [isA<ScanQrIdle>()],
    );
  });

  group('ScanQrBloc - ErrorDialogAccepted', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'resetea a Idle',
      build: () => bloc,
      seed: () => const ScanQrError(
        message: 'Error',
        errorType: ScanErrorType.generic,
      ),
      act: (bloc) => bloc.add(const ErrorDialogAccepted()),
      expect: () => [isA<ScanQrIdle>()],
    );
  });

  group('ScanQrBloc - SuccessDialogAccepted', () {
    test('emite navegaci?n a Home', () async {
      final navigation = <ScanQrNavigation>[];
      bloc.navigationStream.listen(navigation.add);

      bloc.add(const SuccessDialogAccepted());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(navigation, [isA<ScanQrNavigateToHome>()]);
    });
  });

  group('ScanQrBloc - GetGuestByQrCode failure', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando el repositorio falla',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any())).thenAnswer(
          (_) async => const Left(NetworkFailure('Sin conexi?n')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-ABC12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.qrNotFound,
        ),
      ],
    );
  });

  group('ScanQrBloc - Validation messages', () {
    test('emite validation message cuando count < 1 en confirm', () async {
      final messages = <ScanQrValidationMessage>[];
      bloc.validationStream.listen(messages.add);

      // Seed con guestCount = 0 (edge case)
      final invState = const ScanQrInvitationInput(
        guestName: 'Test',
        validUntilFormatted: null,
        createdByName: 'Admin',
        maxUses: 5,
        remainingUses: 3,
        lastUsedDateFormatted: null,
        remainingUsesColor: Colors.green,
        guestCount: 0,
        isConfirming: false,
        guestId: 'inv-1',
        wasUsedRecently: false,
        lastScanCount: 1,
      );

      // Force state via seed event
      bloc.emit(invState);
      bloc.add(const ConfirmGuestEntry());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(messages, isNotEmpty);
      expect(messages.first.type, ValidationMessageType.error);
    });
  });

  group('ScanQrState', () {
    test('ScanQrIdle es instanciable', () {
      const state = ScanQrIdle();
      expect(state, isA<ScanQrState>());
    });

    test('ScanQrProcessing es instanciable', () {
      const state = ScanQrProcessing();
      expect(state, isA<ScanQrState>());
    });

    test('ScanQrSuccess contiene datos correctos', () {
      const state = ScanQrSuccess(
        guestName: 'Juan',
        accessTypeLabel: 'Free Pass / Personal',
      );
      expect(state.guestName, 'Juan');
      expect(state.accessTypeLabel, 'Free Pass / Personal');
    });

    test('ScanQrError contiene datos correctos', () {
      const state = ScanQrError(
        message: 'Error test',
        errorType: ScanErrorType.invalidQr,
      );
      expect(state.message, 'Error test');
      expect(state.errorType, ScanErrorType.invalidQr);
    });

    test('ScanQrInvitationInput.copyWith preserva valores no cambiados', () {
      final state = const ScanQrInvitationInput(
        guestName: 'Test',
        validUntilFormatted: '31/12/2024',
        createdByName: 'Admin',
        maxUses: 5,
        remainingUses: 3,
        lastUsedDateFormatted: null,
        remainingUsesColor: Colors.green,
        guestCount: 1,
        isConfirming: false,
        guestId: 'inv-1',
        wasUsedRecently: false,
        lastScanCount: 1,
      );

      final updated = state.copyWith(guestCount: 2, isConfirming: true);
      expect(updated.guestCount, 2);
      expect(updated.isConfirming, true);
      expect(updated.guestName, 'Test');
      expect(updated.remainingUses, 3);
      expect(updated.maxUses, 5);
    });
  });

  group('ScanQrBloc - Invitaci?n con validez expirada', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando la invitaci?n expir?',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(_invitationGuest(
                  validUntil: DateTime(2024, 1, 1),
                )));
        when(() => mockValidateInvitationValidity(any()))
            .thenAnswer((_) async => Left(QrFailure.invitationExpired()));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-INV12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.invitationExpired,
        ),
      ],
    );

    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando no hay dia operativo activo',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(_invitationGuest()));
        when(() => mockValidateInvitationValidity(any()))
            .thenAnswer((_) async => Left(QrFailure.noActiveOperationalDay()));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-INV12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.noActiveOperationalDay,
        ),
      ],
    );

    blocTest<ScanQrBloc, ScanQrState>(
      'emite [Processing, Error] cuando dia operativo no coincide',
      build: () {
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(_invitationGuest()));
        when(() => mockValidateInvitationValidity(any()))
            .thenAnswer((_) async => Left(QrFailure.notForToday()));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-INV12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.notForToday,
        ),
      ],
    );

    blocTest<ScanQrBloc, ScanQrState>(
      'emite Error cuando dia operativo no coincide incluso con re-escaneo reciente',
      build: () {
        final guest = _invitationGuest(
          totalVisits: 2,
          maxUses: 5,
          lastUsedDate: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(guest));
        when(() => mockValidateInvitationValidity(any()))
            .thenAnswer((_) async => Left(QrFailure.notForToday()));
        when(() => mockGetLastScanCount(any()))
            .thenAnswer((_) async => const Right(2));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-INV12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrError>().having(
          (s) => s.errorType,
          'errorType',
          ScanErrorType.notForToday,
        ),
      ],
    );
  });

  group('ScanQrBloc - Invitaci?n con validityDescription', () {
    blocTest<ScanQrBloc, ScanQrState>(
      'InvitationInput incluye validityDescription para operationalDay',
      build: () {
        final guest = GuestModel(
          id: 'inv-1',
          name: 'Invitaci\u00f3n Viernes',
          dni: 'INV-123',
          qrCode: 'COSMO-INV12345',
          createdBy: 'user-1',
          createdByName: 'Creador',
          createdAt: DateTime(2024, 1, 1),
          isActive: true,
          totalVisits: 0,
          maxUses: 5,
          isInvitation: true,
          validityType: InvitationValidityType.operationalDay,
          validForDate: DateTime(2025, 1, 31),
          validUntil: DateTime(2025, 1, 31),
        );
        when(() => mockValidateQrCode(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => mockGetGuestByQrCode(any()))
            .thenAnswer((_) async => Right(guest));
        when(() => mockValidateInvitationValidity(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const QrCodeDetected('COSMO-INV12345')),
      expect: () => [
        isA<ScanQrProcessing>(),
        isA<ScanQrInvitationInput>()
            .having((s) => s.validityDescription, 'validityDescription',
                contains('31/1/2025')),
      ],
    );
  });
}
