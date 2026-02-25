part of 'generate_invitation_cubit.dart';

/// Estado base para el cubit de generación de invitaciones
sealed class GenerateInvitationState extends Equatable {
  const GenerateInvitationState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - formulario listo para llenar
class GenerateInvitationInitial extends GenerateInvitationState {
  const GenerateInvitationInitial();
}

/// Estado de carga - generando invitación
class GenerateInvitationLoading extends GenerateInvitationState {
  const GenerateInvitationLoading();
}

/// Estado de éxito - invitación generada
class GenerateInvitationSuccess extends GenerateInvitationState {
  final GuestModel invitation;
  final String qrCode;

  const GenerateInvitationSuccess({required this.invitation, required this.qrCode});

  @override
  List<Object?> get props => [invitation, qrCode];
}

/// Estado de error
class GenerateInvitationError extends GenerateInvitationState {
  final String message;

  const GenerateInvitationError(this.message);

  @override
  List<Object?> get props => [message];
}
