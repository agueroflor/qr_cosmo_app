import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_cosmo_app/domain/repositories/guest_repository.dart';
import 'package:qr_cosmo_app/domain/usecases/generate_qr/create_guest_usecase.dart';
import 'package:qr_cosmo_app/domain/usecases/generate_qr/generate_qr_code_usecase.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';

part 'generate_qr_state.dart';

/// Cubit para gestionar la generación de códigos QR
class GenerateQrCubit extends Cubit<GenerateQrState> {
  final GuestRepository _guestRepository;
  final CreateGuestUseCase _createGuestUseCase;
  final GenerateQrCodeUseCase _generateQrCodeUseCase;

  GenerateQrCubit(
    this._guestRepository,
    this._createGuestUseCase,
    this._generateQrCodeUseCase,
  ) : super(const GenerateQrInitial());

  /// Genera un nuevo QR para un invitado
  Future<void> generateQr({
    required String name,
    required String dni,
    required String userId,
    required String userName,
  }) async {
    emit(const GenerateQrLoading());

    // 1. Verificar si el DNI ya existe
    final existingResult = await _guestRepository.getByDni(dni.trim());

    final dniCheckFailed = existingResult.fold(
      (failure) => failure.message,
      (existingGuest) {
        if (existingGuest != null && existingGuest.isActive) {
          return 'Ya existe un invitado activo con este DNI';
        }
        return null;
      },
    );

    if (dniCheckFailed != null) {
      emit(GenerateQrError(dniCheckFailed));
      return;
    }

    // 2. Generar código QR
    final now = DateTime.now();
    final guestId = now.millisecondsSinceEpoch.toString();

    final qrResult = await _generateQrCodeUseCase(
      GenerateQrCodeParams(
        guestId: guestId,
        dni: dni.trim(),
        createdAt: now,
      ),
    );

    final qrCode = qrResult.fold(
      (failure) => null,
      (qrCode) => qrCode,
    );

    if (qrCode == null) {
      emit(const GenerateQrError('Error al generar el código QR'));
      return;
    }

    // 3. Crear el guest model
    final newGuest = GuestModel(
      id: guestId,
      name: name.trim(),
      dni: dni.trim(),
      qrCode: qrCode,
      createdBy: userId,
      createdByName: userName,
      createdAt: now,
      isActive: true,
      totalVisits: 0,
      ownerId: userId,
    );

    // 4. Guardar en repositorio
    final createResult = await _createGuestUseCase(
      CreateGuestParams(guest: newGuest),
    );

    createResult.fold(
      (failure) => emit(GenerateQrError('Error al guardar: ${failure.message}')),
      (_) => emit(GenerateQrSuccess(guest: newGuest, qrCode: qrCode)),
    );
  }

  /// Resetea el estado para generar otro QR
  void resetForm() {
    emit(const GenerateQrInitial());
  }
}
