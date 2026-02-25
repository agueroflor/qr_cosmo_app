import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_cosmo_app/core/core.dart';
import 'package:qr_cosmo_app/domain/errors/failures.dart';

import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/data/models/models.dart';
import 'package:qr_cosmo_app/presentation/theme/theme.dart';
import 'package:qr_cosmo_app/core/services/services.dart';
import 'package:qr_cosmo_app/presentation/presentation.dart';
import 'package:qr_cosmo_app/presentation/errors/failure_message_mapper.dart';

part 'scan_qr_event.dart';
part 'scan_qr_state.dart';

/// Typedef para inyectar chequeo de conectividad (testable)
typedef ConnectivityChecker = Future<bool> Function();

/// Bloc para el escaneo de códigos QR
/// Consume UseCases para toda la lógica de negocio
class ScanQrBloc extends Bloc<ScanQrEvent, ScanQrState> {
  final ValidateQrCodeUseCase _validateQrCodeUseCase;
  final GetGuestByQrCodeUseCase _getGuestByQrCodeUseCase;
  final ProcessGuestEntryUseCase _processGuestEntryUseCase;
  final GetLastScanCountUseCase _getLastScanCountUseCase;
  final ValidateInvitationValidityUseCase _validateInvitationValidityUseCase;
  final ScanObserverService _scanObserver;
  final ConnectivityChecker _connectivityChecker;

  // Usuario actual
  String _currentUserId = 'unknown';
  String _currentUserName = 'Unknown';

  // Guest actual (necesario para operaciones post-scan)
  GuestModel? _currentGuest;

  // Stream controllers para side effects (no reemplazan estado)
  final _validationController =
      StreamController<ScanQrValidationMessage>.broadcast();
  final _navigationController = StreamController<ScanQrNavigation>.broadcast();

  /// Stream de mensajes de validación (snackbars)
  Stream<ScanQrValidationMessage> get validationStream =>
      _validationController.stream;

  /// Stream de efectos de navegación
  Stream<ScanQrNavigation> get navigationStream => _navigationController.stream;

  ScanQrBloc({
    required ValidateQrCodeUseCase validateQrCodeUseCase,
    required GetGuestByQrCodeUseCase getGuestByQrCodeUseCase,
    required ProcessGuestEntryUseCase processGuestEntryUseCase,
    required GetLastScanCountUseCase getLastScanCountUseCase,
    required ValidateInvitationValidityUseCase
    validateInvitationValidityUseCase,
    ScanObserverService? scanObserver,
    ConnectivityChecker? connectivityChecker,
  }) : _validateQrCodeUseCase = validateQrCodeUseCase,
       _getGuestByQrCodeUseCase = getGuestByQrCodeUseCase,
       _processGuestEntryUseCase = processGuestEntryUseCase,
       _getLastScanCountUseCase = getLastScanCountUseCase,
       _validateInvitationValidityUseCase = validateInvitationValidityUseCase,
       _scanObserver = scanObserver ?? ScanObserverService.instance,
       _connectivityChecker =
           connectivityChecker ?? ConnectivityService.hasInternetConnection,
       super(const ScanQrIdle()) {
    on<QrCodeDetected>(_onQrCodeDetected);
    on<GuestCountChanged>(_onGuestCountChanged);
    on<GuestCountIncremented>(_onGuestCountIncremented);
    on<GuestCountDecremented>(_onGuestCountDecremented);
    on<ConfirmGuestEntry>(_onConfirmGuestEntry);
    on<ScanAgainRequested>(_onScanAgainRequested);
    on<SuccessDialogAccepted>(_onSuccessDialogAccepted);
    on<ErrorDialogAccepted>(_onErrorDialogAccepted);
  }

  /// Configura el usuario actual
  void setCurrentUser(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
  }

  // =====================================================
  // EVENT HANDLERS
  // =====================================================

  Future<void> _onQrCodeDetected(
    QrCodeDetected event,
    Emitter<ScanQrState> emit,
  ) async {
    if (state is ScanQrProcessing) return;

    emit(const ScanQrProcessing());

    try {
      // 1. Verificar conexión
      final hasConnection = await _connectivityChecker();
      if (!hasConnection) {
        _scanObserver.onNoInternet(
          qrCode: event.qrCode,
          scannedBy: _currentUserId,
          scannedByName: _currentUserName,
        );
        emit(
          ScanQrError(
            message: mapFailureToMessage(const NetworkFailure()),
            errorType: ScanErrorType.noConnection,
          ),
        );
        return;
      }

      // 2. Validar formato QR via UseCase
      final validationResult = await _validateQrCodeUseCase(
        ValidateQrCodeParams(qrCode: event.qrCode),
      );

      final isValid = validationResult.fold((_) => false, (isValid) => isValid);

      if (!isValid) {
        _scanObserver.onInvalidQR(
          qrCode: event.qrCode,
          scannedBy: _currentUserId,
          scannedByName: _currentUserName,
          errorMessage: mapFailureToMessage(QrFailure.invalidFormat()),
        );
        emit(
          ScanQrError(
            message: mapFailureToMessage(QrFailure.invalidFormat()),
            errorType: ScanErrorType.invalidQr,
          ),
        );
        return;
      }

      // 3. Buscar guest via UseCase
      final guestResult = await _getGuestByQrCodeUseCase(
        GetGuestByQrCodeParams(qrCode: event.qrCode),
      );

      final guest = guestResult.fold((failure) => null, (guest) => guest);

      if (guest == null) {
        _scanObserver.onInvalidQR(
          qrCode: event.qrCode,
          scannedBy: _currentUserId,
          scannedByName: _currentUserName,
          errorMessage: mapFailureToMessage(QrFailure.notFound()),
        );
        emit(
          ScanQrError(
            message: mapFailureToMessage(QrFailure.notFound()),
            errorType: ScanErrorType.qrNotFound,
          ),
        );
        return;
      }

      // 4. Verificar si está activo
      if (!guest.isActive) {
        _scanObserver.onInactiveQR(
          qrCode: event.qrCode,
          guest: guest,
          scannedBy: _currentUserId,
          scannedByName: _currentUserName,
        );
        emit(
          ScanQrError(
            message: mapFailureToMessage(QrFailure.deactivated()),
            errorType: ScanErrorType.qrDeactivated,
          ),
        );
        return;
      }

      _currentGuest = guest;

      // 5. Decidir flujo: invitación vs QR personal
      if (guest.isInvitation) {
        await _handleInvitation(guest, event.qrCode, emit);
      } else {
        if (!guest.canEnterPersonalQr) {
          emit(
            ScanQrError(
              message: mapFailureToMessage(QrFailure.alreadyUsedToday()),
              errorType: ScanErrorType.qrUsedToday,
            ),
          );
          return;
        }
        await _handlePersonalQr(guest, event.qrCode, emit);
      }
    } catch (e, stackTrace) {
      _scanObserver.onException(
        qrCode: event.qrCode,
        scannedBy: _currentUserId,
        scannedByName: _currentUserName,
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        ScanQrError(
          message: mapFailureToMessage(UnexpectedFailure(e.toString())),
          errorType: ScanErrorType.generic,
        ),
      );
    }
  }

  Future<void> _handleInvitation(
    GuestModel guest,
    String qrCode,
    Emitter<ScanQrState> emit,
  ) async {
    // 1. Validar vigencia (día operativo / expiración / ilimitado)
    final validityResult = await _validateInvitationValidityUseCase(
      ValidateInvitationValidityParams(
        guest: guest,
        currentDateTime: DateTime.now(),
      ),
    );

    final validityFailure = validityResult.fold(
      (failure) => failure,
      (_) => null,
    );

    if (validityFailure != null) {
      final errorType = _mapValidityFailureToErrorType(validityFailure);
      emit(ScanQrError(
        message: mapFailureToMessage(validityFailure),
        errorType: errorType,
      ));
      return;
    }

    // 2. Validar usos restantes
    if (!guest.hasRemainingUses) {
      _scanObserver.onNoRemainingUses(
        qrCode: qrCode,
        guest: guest,
        scannedBy: _currentUserId,
        scannedByName: _currentUserName,
      );

      emit(
        ScanQrError(
          message: mapFailureToMessage(QrFailure.maxUsesReached(guest.maxUses ?? 0)),
          errorType: ScanErrorType.maxUsesReached,
        ),
      );
      return;
    }

    // 3. Entrada normal
    _emitInvitationInputState(guest, 1, emit);
  }

  ScanErrorType _mapValidityFailureToErrorType(Failure failure) {
    if (failure is QrFailure) {
      return switch (failure.code) {
        'INVITATION_EXPIRED' => ScanErrorType.invitationExpired,
        'INVALID_OPERATIONAL_DAY' => ScanErrorType.invalidOperationalDay,
        'NOT_FOR_TODAY' => ScanErrorType.notForToday,
        'NO_ACTIVE_OPERATIONAL_DAY' => ScanErrorType.noActiveOperationalDay,
        'MAX_USES_REACHED' => ScanErrorType.maxUsesReached,
        'QR_DEACTIVATED' => ScanErrorType.qrDeactivated,
        _ => ScanErrorType.generic,
      };
    }
    return ScanErrorType.generic;
  }

 Future<void> _handlePersonalQr(
  GuestModel guest,
  String qrCode,
  Emitter<ScanQrState> emit,
) async {
  if (guest.wasUsedThisOperationalDay) {
    _scanObserver.onAlreadyUsedToday(
      qrCode: qrCode,
      guest: guest,
      scannedBy: _currentUserId,
      scannedByName: _currentUserName,
    );

    emit(
      ScanQrError(
        message: mapFailureToMessage(QrFailure.alreadyUsedToday()),
        errorType: ScanErrorType.qrUsedToday,
      ),
    );
    return;
  }

  await _processEntry(guest, 1, emit);
}


  void _emitInvitationInputState(
    GuestModel guest,
    int initialCount,
    Emitter<ScanQrState> emit,
  ) {
    final remainingUsesColor = guest.remainingUses > 0
        ? AppColors.success
        : AppColors.error;

    // Generar descripción de validez según tipo
    String? validityDesc;
    switch (guest.validityType) {
      case InvitationValidityType.operationalDay:
        validityDesc = guest.validForDate != null
            ? 'Noche del ${formatDate(guest.validForDate!)}'
            : null;
      case InvitationValidityType.expirationDate:
        validityDesc = guest.validForDate != null
            ? 'Válida hasta ${formatDate(guest.validForDate!)}'
            : null;
      case InvitationValidityType.unlimited:
        validityDesc = 'Sin vencimiento';
    }

    emit(
      ScanQrInvitationInput(
        guestName: guest.name,
        validUntilFormatted: guest.validForDate != null
            ? formatDate(guest.validForDate!)
            : (guest.validUntil != null ? formatDate(guest.validUntil!) : null),
        createdByName: guest.createdByName,
        maxUses: guest.maxUses ?? 0,
        remainingUses: guest.remainingUses,
        lastUsedDateFormatted: guest.lastUsedDate != null
            ? formatDateTime(guest.lastUsedDate!)
            : null,
        remainingUsesColor: remainingUsesColor,
        guestCount: initialCount,
        isConfirming: false,
        guestId: guest.id,
        wasUsedRecently: guest.wasUsedRecently,
        lastScanCount: initialCount,
        validityDescription: validityDesc,
      ),
    );
  }

  Future<int> _getLastScanCountForGuest(GuestModel guest) async {
    final result = await _getLastScanCountUseCase(
      GetLastScanCountParams(guestId: guest.id),
    );

    return result.fold((_) => 1, (count) => count > 0 ? count : 1);
  }

  void _onGuestCountChanged(
    GuestCountChanged event,
    Emitter<ScanQrState> emit,
  ) {
    final currentState = state;
    if (currentState is! ScanQrInvitationInput) return;

    final maxCount = currentState.remainingUses > 0
        ? currentState.remainingUses
        : currentState.lastScanCount;
    final validCount = event.count.clamp(1, maxCount);

    emit(currentState.copyWith(guestCount: validCount));
  }

  void _onGuestCountIncremented(
    GuestCountIncremented event,
    Emitter<ScanQrState> emit,
  ) {
    final currentState = state;
    if (currentState is! ScanQrInvitationInput) return;

    final maxCount = currentState.remainingUses > 0
        ? currentState.remainingUses
        : currentState.lastScanCount;

    if (currentState.guestCount < maxCount) {
      emit(currentState.copyWith(guestCount: currentState.guestCount + 1));
    }
  }

  void _onGuestCountDecremented(
    GuestCountDecremented event,
    Emitter<ScanQrState> emit,
  ) {
    final currentState = state;
    if (currentState is! ScanQrInvitationInput) return;

    if (currentState.guestCount > 1) {
      emit(currentState.copyWith(guestCount: currentState.guestCount - 1));
    }
  }

  Future<void> _onConfirmGuestEntry(
    ConfirmGuestEntry event,
    Emitter<ScanQrState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ScanQrInvitationInput) return;
    if (currentState.isConfirming) return;

    final count = currentState.guestCount;
    final maxCount = currentState.remainingUses;

    // Validaciones
    if (count < 1) {
      _validationController.add(
        const ScanQrValidationMessage(
          message: msgMinGuestCount,
          type: ValidationMessageType.error,
        ),
      );
      return;
    }

    if (currentState.wasUsedRecently && maxCount <= 0) {
      if (count != currentState.lastScanCount) {
        _validationController.add(
          ScanQrValidationMessage(
            message: msgSameScanCountRequired(currentState.lastScanCount),
            type: ValidationMessageType.warning,
          ),
        );
        return;
      }
    } else if (maxCount <= 0) {
      _validationController.add(
        const ScanQrValidationMessage(
          message: msgNoRemainingUses,
          type: ValidationMessageType.error,
        ),
      );
      return;
    } else if (count > maxCount) {
      _validationController.add(
        ScanQrValidationMessage(
          message: msgMaxGuestCount(maxCount),
          type: ValidationMessageType.error,
        ),
      );
      return;
    }

    emit(currentState.copyWith(isConfirming: true));

    final guest = _currentGuest;
    if (guest == null) {
      emit(
        const ScanQrError(
          message: msgGuestNotFoundInternal,
          errorType: ScanErrorType.generic,
        ),
      );
      return;
    }

    try {
      await _processEntry(guest, count, emit);
    } catch (e, stackTrace) {
      _scanObserver.onException(
        qrCode: guest.qrCode,
        scannedBy: _currentUserId,
        scannedByName: _currentUserName,
        error: e,
        stackTrace: stackTrace,
        guest: guest,
      );
      emit(
        ScanQrError(
          message: mapFailureToMessage(UnexpectedFailure(e.toString())),
          errorType: ScanErrorType.generic,
        ),
      );
    }
  }

Future<void> _processEntry(
  GuestModel guest,
  int count,
  Emitter<ScanQrState> emit,
) async {
  final result = await _processGuestEntryUseCase(
    ProcessGuestEntryParams(
      guest: guest,
      count: count,
      scannerId: _currentUserId,
      scannerName: _currentUserName,
    ),
  );

  await result.fold(
    (failure) async {
      final errorType = failure is QrFailure && failure.code == 'ALREADY_USED_TODAY'
          ? ScanErrorType.qrUsedToday
          : ScanErrorType.generic;
      emit(
        ScanQrError(
          message: mapFailureToMessage(failure),
          errorType: errorType,
        ),
      );
    },
    (_) async {
      // 🔄 REFRESH DEL GUEST (CLAVE)
      final refreshedGuestResult = await _getGuestByQrCodeUseCase(
        GetGuestByQrCodeParams(qrCode: guest.qrCode),
      );

      final refreshedGuest = refreshedGuestResult.fold(
        (_) => null,
        (g) => g,
      );

      if (refreshedGuest != null) {
        _currentGuest = refreshedGuest;
      }

      _scanObserver.onAccessGranted(
        qrCode: guest.qrCode,
        guest: refreshedGuest ?? guest,
        scannedBy: _currentUserId,
        scannedByName: _currentUserName,
        guestCount: count,
        totalVisitsAfterScan:
            (refreshedGuest ?? guest).totalVisits + count,
      );

      final accessTypeLabel = guest.isInvitation
          ? 'Invitación'
          : 'Free Pass / Personal';

      emit(
        ScanQrSuccess(
          guestName: guest.name,
          accessTypeLabel: accessTypeLabel,
        ),
      );
    },
  );
}


  void _onScanAgainRequested(
    ScanAgainRequested event,
    Emitter<ScanQrState> emit,
  ) {
    _currentGuest = null;
    emit(const ScanQrIdle());
  }

  void _onSuccessDialogAccepted(
    SuccessDialogAccepted event,
    Emitter<ScanQrState> emit,
  ) {
    _navigationController.add(const ScanQrNavigateToHome());
  }

  void _onErrorDialogAccepted(
    ErrorDialogAccepted event,
    Emitter<ScanQrState> emit,
  ) {
    _currentGuest = null;
    emit(const ScanQrIdle());
  }

  @override
  Future<void> close() {
    _validationController.close();
    _navigationController.close();
    return super.close();
  }
}

// =====================================================
// EFECTOS DE NAVEGACIÓN
// =====================================================

/// Efecto de navegación base
sealed class ScanQrNavigation {
  const ScanQrNavigation();
}

/// Navegar a la pantalla principal
class ScanQrNavigateToHome extends ScanQrNavigation {
  const ScanQrNavigateToHome();
}
