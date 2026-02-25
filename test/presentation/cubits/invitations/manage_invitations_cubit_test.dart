import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/data/models/models.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/presentation/presentation.dart';

class MockInvitationRepository extends Mock implements InvitationRepository {}

void main() {
  late ManageInvitationsCubit cubit;
  late MockInvitationRepository mockRepository;

  final testInvitation1 = GuestModel(
    id: 'inv-1',
    name: 'Invitación VIP',
    dni: '12345678',
    qrCode: 'COSMO-INV00001',
    createdBy: 'user-1',
    createdByName: 'Admin',
    createdAt: DateTime(2024, 1, 15),
    isActive: true,
    totalVisits: 2,
    isInvitation: true,
    maxUses: 5,
  );

  final testInvitation2 = GuestModel(
    id: 'inv-2',
    name: 'Invitación Corporativa',
    dni: '87654321',
    qrCode: 'COSMO-INV00002',
    createdBy: 'user-1',
    createdByName: 'Admin',
    createdAt: DateTime(2024, 1, 20),
    isActive: true,
    totalVisits: 5,
    isInvitation: true,
    maxUses: 5,
  );

  final testInvitation3 = GuestModel(
    id: 'inv-3',
    name: 'Invitación Inactiva',
    dni: '11111111',
    qrCode: 'COSMO-INV00003',
    createdBy: 'user-2',
    createdByName: 'Manager',
    createdAt: DateTime(2024, 1, 10),
    isActive: false,
    totalVisits: 0,
    isInvitation: true,
    maxUses: 3,
  );

  final testInvitations = [testInvitation1, testInvitation2, testInvitation3];

  setUp(() {
    mockRepository = MockInvitationRepository();
    cubit = ManageInvitationsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('ManageInvitationsCubit', () {
    test('estado inicial debe ser ManageInvitationsInitial', () {
      expect(cubit.state, const ManageInvitationsInitial());
    });

    blocTest<ManageInvitationsCubit, ManageInvitationsState>(
      'emite [Loading, Loaded] cuando loadInvitations tiene éxito',
      build: () {
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right(testInvitations));
        return cubit;
      },
      act: (cubit) => cubit.loadInvitations(),
      expect: () => [
        const ManageInvitationsLoading(),
        isA<ManageInvitationsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepository.getAll()).called(1);
      },
    );

    blocTest<ManageInvitationsCubit, ManageInvitationsState>(
      'ordena invitaciones por fecha de creación (más recientes primero)',
      build: () {
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right(testInvitations));
        return cubit;
      },
      act: (cubit) => cubit.loadInvitations(),
      verify: (cubit) {
        final state = cubit.state as ManageInvitationsLoaded;
        // inv-2 (20 ene) debe estar primero, luego inv-1 (15 ene), luego inv-3 (10 ene)
        expect(state.invitations[0].id, 'inv-2');
        expect(state.invitations[1].id, 'inv-1');
        expect(state.invitations[2].id, 'inv-3');
      },
    );

    blocTest<ManageInvitationsCubit, ManageInvitationsState>(
      'emite [Loading, Error] cuando loadInvitations falla',
      build: () {
        when(() => mockRepository.getAll()).thenAnswer(
          (_) async => const Left(DatabaseFailure('Error de conexión')),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadInvitations(),
      expect: () => [
        const ManageInvitationsLoading(),
        const ManageInvitationsError('Error de conexión'),
      ],
    );

    blocTest<ManageInvitationsCubit, ManageInvitationsState>(
      'deleteInvitation emite estados correctos al eliminar exitosamente',
      build: () {
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right([testInvitation1]));
        when(() => mockRepository.delete('inv-1', 'user-1'))
            .thenAnswer((_) async => const Right(null));
        return cubit;
      },
      seed: () => ManageInvitationsLoaded(testInvitations),
      act: (cubit) => cubit.deleteInvitation('inv-1', 'user-1'),
      expect: () => [
        isA<ManageInvitationsOperationInProgress>(),
        const ManageInvitationsLoading(),
        isA<ManageInvitationsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepository.delete('inv-1', 'user-1')).called(1);
        verify(() => mockRepository.getAll()).called(1);
      },
    );

    blocTest<ManageInvitationsCubit, ManageInvitationsState>(
      'deleteInvitation emite error con mensaje amigable cuando falla por permisos',
      build: () {
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right(testInvitations));
        when(() => mockRepository.delete('inv-1', 'user-2')).thenAnswer(
          (_) async => const Left(DatabaseFailure('403', code: 'PERMISSION_DENIED')),
        );
        return cubit;
      },
      seed: () => ManageInvitationsLoaded(testInvitations),
      act: (cubit) => cubit.deleteInvitation('inv-1', 'user-2'),
      expect: () => [
        isA<ManageInvitationsOperationInProgress>(),
        isA<ManageInvitationsLoaded>(), // Restaura estado previo
        const ManageInvitationsError(
          'No tienes permiso para eliminar esta invitación. Solo el dueño puede eliminarla.',
          code: 'PERMISSION_DENIED',
        ),
        const ManageInvitationsLoading(),
        isA<ManageInvitationsLoaded>(),
      ],
    );

    blocTest<ManageInvitationsCubit, ManageInvitationsState>(
      'refresh() es equivalente a loadInvitations()',
      build: () {
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right(testInvitations));
        return cubit;
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        const ManageInvitationsLoading(),
        isA<ManageInvitationsLoaded>(),
      ],
    );
  });

  group('ManageInvitationsState', () {
    test('ManageInvitationsInitial tiene props vacías', () {
      const state = ManageInvitationsInitial();
      expect(state.props, isEmpty);
    });

    test('ManageInvitationsLoading incluye message en props', () {
      const state = ManageInvitationsLoading(message: 'Cargando...');
      expect(state.props, ['Cargando...']);
    });

    test('ManageInvitationsLoaded calcula estadísticas correctamente', () {
      final state = ManageInvitationsLoaded(testInvitations);

      expect(state.totalCount, 3);
      // inv-1 tiene 2/5 usos (válida), inv-2 tiene 5/5 (agotada)
      // Solo inv-1 es válida (activa y con usos restantes)
      expect(state.activeCount, 1);
      // inv-2 tiene 5/5 usos (agotada)
      expect(state.exhaustedCount, 1);
      // inv-3 está inactiva
      expect(state.inactiveCount, 1);
    });

    test('ManageInvitationsError incluye message y code en props', () {
      const state = ManageInvitationsError('Error', code: 'ERR_001');
      expect(state.props, ['Error', 'ERR_001']);
    });

    test('ManageInvitationsOperationInProgress incluye invitations y message', () {
      final state = ManageInvitationsOperationInProgress(
        invitations: testInvitations,
        operationMessage: 'Eliminando...',
      );
      expect(state.props, [testInvitations, 'Eliminando...']);
    });
  });

  group('filterInvitations', () {
    test('filtra por búsqueda de nombre', () {
      final result = ManageInvitationsCubit.filterInvitations(
        testInvitations,
        'VIP',
        'all',
      );
      expect(result.length, 1);
      expect(result[0].name, 'Invitación VIP');
    });

    test('filtra por búsqueda case-insensitive', () {
      final result = ManageInvitationsCubit.filterInvitations(
        testInvitations,
        'vip',
        'all',
      );
      expect(result.length, 1);
      expect(result[0].name, 'Invitación VIP');
    });

    test('filtra por estado válido', () {
      final result = ManageInvitationsCubit.filterInvitations(
        testInvitations,
        '',
        'valid',
      );
      // Solo inv-1 es válida (activa y con usos restantes)
      expect(result.length, 1);
      expect(result[0].id, 'inv-1');
    });

    test('filtra por estado inactivo', () {
      final result = ManageInvitationsCubit.filterInvitations(
        testInvitations,
        '',
        'inactive',
      );
      expect(result.length, 1);
      expect(result[0].id, 'inv-3');
    });

    test('filtra por estado agotado', () {
      final result = ManageInvitationsCubit.filterInvitations(
        testInvitations,
        '',
        'used_up',
      );
      // inv-2 tiene 5/5 usos (agotada)
      expect(result.length, 1);
      expect(result[0].id, 'inv-2');
    });

    test('combina búsqueda y filtro de estado', () {
      final result = ManageInvitationsCubit.filterInvitations(
        testInvitations,
        'Invitación',
        'inactive',
      );
      expect(result.length, 1);
      expect(result[0].id, 'inv-3');
    });

    test('retorna lista vacía si no hay coincidencias', () {
      final result = ManageInvitationsCubit.filterInvitations(
        testInvitations,
        'NoExiste',
        'all',
      );
      expect(result, isEmpty);
    });
  });

  group('getStatusText', () {
    test('retorna INACTIVA para invitación inactiva', () {
      expect(ManageInvitationsCubit.getStatusText(testInvitation3), 'INACTIVA');
    });

    test('retorna AGOTADA para invitación sin usos restantes', () {
      expect(ManageInvitationsCubit.getStatusText(testInvitation2), 'AGOTADA');
    });

    test('retorna ACTIVA para invitación válida', () {
      expect(ManageInvitationsCubit.getStatusText(testInvitation1), 'ACTIVA');
    });
  });
}
