import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/data/models/models.dart';

part 'generate_invitation_state.dart';

/// Cubit para gestionar la generación de invitaciones con QR
class GenerateInvitationCubit extends Cubit<GenerateInvitationState> {
  final InvitationRepository _invitationRepository;
  final GenerateQrCodeUseCase _generateQrCodeUseCase;

  GenerateInvitationCubit(
    this._invitationRepository,
    this._generateQrCodeUseCase,
  ) : super(const GenerateInvitationInitial());

  /// Genera una nueva invitación con QR
  Future<void> generateInvitation({
    required String name,
    required int maxUses,
    required InvitationValidityType validityType,
    DateTime? validForDate,
    required String userId,
    required String userName,
  }) async {
    emit(const GenerateInvitationLoading());

    final now = DateTime.now();
    final invitationId = now.millisecondsSinceEpoch.toString();

    // 1. Generar código QR
    final qrResult = await _generateQrCodeUseCase(
      GenerateQrCodeParams(
        guestId: invitationId,
        dni: 'INV-$invitationId',
        createdAt: now,
      ),
    );

    final qrCode = qrResult.fold(
      (failure) => null,
      (qrCode) => qrCode,
    );

    if (qrCode == null) {
      emit(const GenerateInvitationError('Error al generar el código QR'));
      return;
    }

    // 2. Crear el modelo de invitación
    final newInvitation = GuestModel(
      id: invitationId,
      name: name.trim(),
      dni: 'INV-$invitationId',
      qrCode: qrCode,
      createdBy: userId,
      createdByName: userName,
      createdAt: now,
      isActive: true,
      totalVisits: 0,
      ownerId: userId,
      isInvitation: true,
      maxUses: maxUses,
      validityType: validityType,
      validForDate: validForDate,
      validUntil: validForDate, // Mantener validUntil sync para compat
    );

    // 3. Guardar en repositorio
    final createResult = await _invitationRepository.create(newInvitation);

    createResult.fold(
      (failure) => emit(GenerateInvitationError('Error al guardar: ${failure.message}')),
      (_) => emit(GenerateInvitationSuccess(invitation: newInvitation, qrCode: qrCode)),
    );
  }

  /// Resetea el estado para generar otra invitación
  void resetForm() {
    emit(const GenerateInvitationInitial());
  }
}
