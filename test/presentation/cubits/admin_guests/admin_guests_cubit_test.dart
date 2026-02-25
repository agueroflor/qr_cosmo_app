import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:qr_cosmo_app/domain/errors/failures.dart';
import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import 'package:qr_cosmo_app/presentation/cubits/admin_guests/admin_guests_cubit.dart';

class MockGuestRepository extends Mock implements GuestRepository {}

void main() {
  late AdminGuestsCubit cubit;
  late MockGuestRepository mockRepository;

  final now = DateTime(2025, 2, 1, 12, 0);

  final guestA = GuestModel(
    id: 'guest-a',
    name: 'Alice',
    dni: '11111111',
    qrCode: 'COSMO-AAA11111',
    createdBy: 'user-1',
    createdByName: 'Admin',
    createdAt: now.subtract(const Duration(days: 2)),
    isActive: true,
    totalVisits: 3,
  );

  final guestB = GuestModel(
    id: 'guest-b',
    name: 'Bob',
    dni: '22222222',
    qrCode: 'COSMO-BBB22222',
    createdBy: 'user-1',
    createdByName: 'Admin',
    createdAt: now.subtract(const Duration(days: 1)),
    isActive: true,
    totalVisits: 0,
  );

  setUp(() {
    mockRepository = MockGuestRepository();
    cubit = AdminGuestsCubit(mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('AdminGuestsCubit - initial state', () {
    test('initial state is AdminGuestsInitial', () {
      expect(cubit.state, isA<AdminGuestsInitial>());
    });
  });

  group('AdminGuestsCubit - loadGuests', () {
    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'emits [Loading, Loaded] with guests sorted by createdAt descending',
      build: () {
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right([guestA, guestB]));
        return cubit;
      },
      act: (cubit) => cubit.loadGuests(),
      expect: () => [
        isA<AdminGuestsLoading>(),
        isA<AdminGuestsLoaded>().having(
          (s) => s.guests.map((g) => g.id).toList(),
          'guest ids sorted by createdAt desc',
          ['guest-b', 'guest-a'],
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getAll()).called(1);
      },
    );

    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'emits [Loading, Loaded] with empty list when no guests',
      build: () {
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => const Right([]));
        return cubit;
      },
      act: (cubit) => cubit.loadGuests(),
      expect: () => [
        isA<AdminGuestsLoading>(),
        isA<AdminGuestsLoaded>().having(
          (s) => s.guests,
          'empty guest list',
          isEmpty,
        ),
      ],
    );

    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'emits [Loading, Error] when repository fails',
      build: () {
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));
        return cubit;
      },
      act: (cubit) => cubit.loadGuests(),
      expect: () => [
        isA<AdminGuestsLoading>(),
        isA<AdminGuestsError>().having(
          (s) => s.message,
          'error message',
          'DB error',
        ),
      ],
    );
  });

  group('AdminGuestsCubit - toggleStatus', () {
    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'toggles status and reloads guests on success',
      build: () {
        when(() => mockRepository.toggleStatus('guest-a', false))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right([guestA.copyWith(isActive: false)]));
        return cubit;
      },
      act: (cubit) => cubit.toggleStatus('guest-a', true),
      expect: () => [
        isA<AdminGuestsLoading>(),
        isA<AdminGuestsLoaded>().having(
          (s) => s.guests.first.isActive,
          'guest is now inactive',
          false,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.toggleStatus('guest-a', false)).called(1);
        verify(() => mockRepository.getAll()).called(1);
      },
    );

    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'emits Error when toggle fails',
      build: () {
        when(() => mockRepository.toggleStatus('guest-a', false))
            .thenAnswer((_) async => const Left(DatabaseFailure('Toggle failed')));
        return cubit;
      },
      act: (cubit) => cubit.toggleStatus('guest-a', true),
      expect: () => [
        isA<AdminGuestsError>().having(
          (s) => s.message,
          'error message',
          'Toggle failed',
        ),
      ],
    );
  });

  group('AdminGuestsCubit - deleteGuest', () {
    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'deletes guest and reloads on success',
      build: () {
        when(() => mockRepository.delete('guest-a', 'user-1'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right([guestB]));
        return cubit;
      },
      act: (cubit) => cubit.deleteGuest('guest-a', 'user-1'),
      expect: () => [
        isA<AdminGuestsLoading>(),
        isA<AdminGuestsLoaded>().having(
          (s) => s.guests.length,
          'one guest remaining',
          1,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.delete('guest-a', 'user-1')).called(1);
      },
    );

    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'emits permission-denied message when PERMISSION_DENIED',
      build: () {
        when(() => mockRepository.delete('guest-a', 'user-2'))
            .thenAnswer((_) async =>
                const Left(DatabaseFailure('Permiso denegado', code: 'PERMISSION_DENIED')));
        return cubit;
      },
      act: (cubit) => cubit.deleteGuest('guest-a', 'user-2'),
      expect: () => [
        isA<AdminGuestsError>().having(
          (s) => s.message,
          'permission denied message',
          'No tienes permiso para eliminar este QR',
        ),
      ],
    );

    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'emits generic error message for other failures',
      build: () {
        when(() => mockRepository.delete('guest-a', 'user-1'))
            .thenAnswer((_) async =>
                const Left(DatabaseFailure('Network error', code: 'NETWORK')));
        return cubit;
      },
      act: (cubit) => cubit.deleteGuest('guest-a', 'user-1'),
      expect: () => [
        isA<AdminGuestsError>().having(
          (s) => s.message,
          'generic error message',
          'Error: Network error',
        ),
      ],
    );
  });

  group('AdminGuestsCubit - updateGuestInfo', () {
    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'updates info and reloads on success',
      build: () {
        when(() => mockRepository.updateInfo('guest-a', 'Alice Updated', '99999999'))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right([
                  guestA.copyWith(name: 'Alice Updated', dni: '99999999'),
                ]));
        return cubit;
      },
      act: (cubit) => cubit.updateGuestInfo('guest-a', 'Alice Updated', '99999999'),
      expect: () => [
        isA<AdminGuestsLoading>(),
        isA<AdminGuestsLoaded>().having(
          (s) => s.guests.first.name,
          'updated name',
          'Alice Updated',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.updateInfo('guest-a', 'Alice Updated', '99999999'))
            .called(1);
      },
    );

    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'emits Error when update fails',
      build: () {
        when(() => mockRepository.updateInfo('guest-a', 'New', '123'))
            .thenAnswer((_) async => const Left(DatabaseFailure('Update failed')));
        return cubit;
      },
      act: (cubit) => cubit.updateGuestInfo('guest-a', 'New', '123'),
      expect: () => [
        isA<AdminGuestsError>().having(
          (s) => s.message,
          'error message',
          'Update failed',
        ),
      ],
    );
  });

  group('AdminGuestsCubit - refresh', () {
    blocTest<AdminGuestsCubit, AdminGuestsState>(
      'refresh delegates to loadGuests',
      build: () {
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => Right([guestA]));
        return cubit;
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<AdminGuestsLoading>(),
        isA<AdminGuestsLoaded>(),
      ],
    );
  });

  group('AdminGuestsState - equatable', () {
    test('AdminGuestsLoaded with same guests are equal', () {
      final state1 = AdminGuestsLoaded([guestA]);
      final state2 = AdminGuestsLoaded([guestA]);
      expect(state1, equals(state2));
    });

    test('AdminGuestsLoaded with different guests are not equal', () {
      final state1 = AdminGuestsLoaded([guestA]);
      final state2 = AdminGuestsLoaded([guestB]);
      expect(state1, isNot(equals(state2)));
    });

    test('AdminGuestsError with same message are equal', () {
      const state1 = AdminGuestsError('error');
      const state2 = AdminGuestsError('error');
      expect(state1, equals(state2));
    });

    test('AdminGuestsError with different messages are not equal', () {
      const state1 = AdminGuestsError('error 1');
      const state2 = AdminGuestsError('error 2');
      expect(state1, isNot(equals(state2)));
    });
  });
}
