part of 'manage_invitations_cubit.dart';

/// Estado base para el cubit de gestión de invitaciones
sealed class ManageInvitationsState extends Equatable {
  const ManageInvitationsState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - antes de cargar datos
class ManageInvitationsInitial extends ManageInvitationsState {
  const ManageInvitationsInitial();
}

/// Estado de carga inicial
class ManageInvitationsLoading extends ManageInvitationsState {
  final String message;

  const ManageInvitationsLoading({this.message = 'Cargando invitaciones...'});

  @override
  List<Object?> get props => [message];
}

/// Estado de éxito con datos cargados
class ManageInvitationsLoaded extends ManageInvitationsState {
  final List<GuestModel> invitations;

  const ManageInvitationsLoaded(this.invitations);

  /// Estadísticas calculadas
  int get totalCount => invitations.length;
  int get activeCount => invitations.where((i) => i.isValidInvitation).length;
  int get exhaustedCount => invitations.where((i) => !i.hasRemainingUses && i.maxUses != null).length;
  int get inactiveCount => invitations.where((i) => !i.isActive).length;

  @override
  List<Object?> get props => [invitations];
}

/// Estado de error
class ManageInvitationsError extends ManageInvitationsState {
  final String message;
  final String? code;

  const ManageInvitationsError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Estado de operación en progreso (delete)
/// Mantiene las invitaciones visibles mientras se procesa
class ManageInvitationsOperationInProgress extends ManageInvitationsState {
  final List<GuestModel> invitations;
  final String operationMessage;

  const ManageInvitationsOperationInProgress({
    required this.invitations,
    required this.operationMessage,
  });

  @override
  List<Object?> get props => [invitations, operationMessage];
}
