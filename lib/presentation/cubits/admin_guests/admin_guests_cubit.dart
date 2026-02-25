import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

part 'admin_guests_state.dart';

/// Cubit for the admin QR management screen.
///
/// Replaces direct FirestoreService usage with GuestRepository,
/// following the same Cubit → Repository pattern used across the app.
class AdminGuestsCubit extends Cubit<AdminGuestsState> {
  final GuestRepository _guestRepository;

  AdminGuestsCubit(this._guestRepository) : super(const AdminGuestsInitial());

  /// Loads all personal guests (non-invitation).
  Future<void> loadGuests() async {
    emit(const AdminGuestsLoading());

    final result = await _guestRepository.getAll();

    result.fold(
      (failure) => emit(AdminGuestsError(failure.message)),
      (guests) {
        final sorted = List<GuestModel>.from(guests)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(AdminGuestsLoaded(sorted));
      },
    );
  }

  /// Toggles active/inactive status of a guest.
  Future<void> toggleStatus(String guestId, bool currentIsActive) async {
    final result = await _guestRepository.toggleStatus(guestId, !currentIsActive);

    await result.fold(
      (failure) async => emit(AdminGuestsError(failure.message)),
      (_) async => await loadGuests(),
    );
  }

  /// Deletes a guest (validates ownership via repository).
  Future<void> deleteGuest(String guestId, String currentUserId) async {
    final result = await _guestRepository.delete(guestId, currentUserId);

    await result.fold(
      (failure) async {
        final message = failure.code == 'PERMISSION_DENIED'
            ? 'No tienes permiso para eliminar este QR'
            : 'Error: ${failure.message}';
        emit(AdminGuestsError(message));
      },
      (_) async => await loadGuests(),
    );
  }

  /// Updates name and DNI of a guest.
  Future<void> updateGuestInfo(String guestId, String name, String dni) async {
    final result = await _guestRepository.updateInfo(guestId, name, dni);

    await result.fold(
      (failure) async => emit(AdminGuestsError(failure.message)),
      (_) async => await loadGuests(),
    );
  }

  Future<void> refresh() => loadGuests();
}
