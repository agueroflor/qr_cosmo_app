import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_cosmo_app/domain/repositories/invitation_repository.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

part 'manage_invitations_state.dart';

/// Cubit para gestionar las invitaciones
class ManageInvitationsCubit extends Cubit<ManageInvitationsState> {
  final InvitationRepository _invitationRepository;

  ManageInvitationsCubit(this._invitationRepository)
      : super(const ManageInvitationsInitial());

  /// Carga todas las invitaciones
  Future<void> loadInvitations() async {
    emit(const ManageInvitationsLoading());

    final result = await _invitationRepository.getAll();

    result.fold(
      (failure) => emit(ManageInvitationsError(failure.message, code: failure.code)),
      (invitations) {
        // Ordenar por fecha de creación (más recientes primero)
        final sorted = List<GuestModel>.from(invitations)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(ManageInvitationsLoaded(sorted));
      },
    );
  }

  /// Elimina varias invitaciones en secuencia
  Future<void> deleteInvitations(
    List<String> invitationIds,
    String currentUserId,
  ) async {
    if (invitationIds.isEmpty) return;

    final currentState = state;
    if (currentState is! ManageInvitationsLoaded) return;

    emit(ManageInvitationsOperationInProgress(
      invitations: currentState.invitations,
      operationMessage:
          'Eliminando ${invitationIds.length} invitación(es)...',
    ));

    String? lastError;
    for (final id in invitationIds) {
      final result = await _invitationRepository.delete(id, currentUserId);
      result.fold(
        (failure) =>
            lastError = _mapDeleteErrorMessage(failure.message, failure.code),
        (_) {},
      );
    }

    if (lastError != null) {
      emit(ManageInvitationsError(lastError!));
    }
    await loadInvitations();
  }

  /// Elimina una invitación
  Future<void> deleteInvitation(String invitationId, String currentUserId) async {
    final currentState = state;

    // Mantener las invitaciones visibles durante la operación
    if (currentState is ManageInvitationsLoaded) {
      emit(ManageInvitationsOperationInProgress(
        invitations: currentState.invitations,
        operationMessage: 'Eliminando invitación...',
      ));
    }

    final result = await _invitationRepository.delete(invitationId, currentUserId);

    await result.fold(
      (failure) async {
        // Restaurar estado previo con error
        if (currentState is ManageInvitationsLoaded) {
          emit(currentState);
        }
        // Emitir error para que la UI pueda mostrar SnackBar
        emit(ManageInvitationsError(
          _mapDeleteErrorMessage(failure.message, failure.code),
          code: failure.code,
        ));
        // Recargar para asegurar consistencia
        await loadInvitations();
      },
      (_) async {
        // Éxito - recargar lista
        await loadInvitations();
      },
    );
  }

  /// Mapea mensajes de error de eliminación a mensajes amigables
  String _mapDeleteErrorMessage(String message, String? code) {
    if (code == 'PERMISSION_DENIED' || message.contains('403')) {
      return 'No tienes permiso para eliminar esta invitación. Solo el dueño puede eliminarla.';
    }
    return 'Error al eliminar invitación: $message';
  }

  /// Filtra invitaciones según búsqueda y estado
  /// Este método es puro y puede usarse desde la UI
  static List<GuestModel> filterInvitations(
    List<GuestModel> invitations,
    String searchQuery,
    String filterStatus,
  ) {
    return invitations.where((invitation) {
      final matchesSearch = searchQuery.isEmpty ||
          invitation.name.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesStatus = filterStatus == 'all' ||
          (filterStatus == 'valid' && invitation.isValidInvitation) ||
          (filterStatus == 'inactive' && !invitation.isActive) ||
          (filterStatus == 'used_up' && !invitation.hasRemainingUses && invitation.maxUses != null) ||
          (filterStatus == 'expired' && invitation.isExpired);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  /// Obtiene el texto de estado de una invitación
  static String getStatusText(GuestModel invitation) {
    if (!invitation.isActive) return 'INACTIVA';
    if (!invitation.hasRemainingUses) return 'AGOTADA';
    if (invitation.isExpired) return 'EXPIRADA';
    return 'ACTIVA';
  }

  /// Refresca la lista de invitaciones
  Future<void> refresh() => loadInvitations();
}
