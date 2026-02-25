// lib/screens/scan_qr/scan_qr_screen.dart
// Pantalla de escaneo QR - Solo UI, sin lógica de negocio
//
// Toda la lógica de negocio vive en ScanQrBloc (presentation/blocs/scan_qr/)
// Esta clase solo:
// - Observa el Bloc
// - Renderiza widgets según el estado
// - Emite eventos al Bloc

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';
import 'package:qr_cosmo_app/presentation/widgets/app/app_app_bar.dart';
import 'package:qr_cosmo_app/core/di/injection.dart';
import 'package:qr_cosmo_app/presentation/screens/home_screen.dart';
import 'package:qr_cosmo_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:qr_cosmo_app/presentation/blocs/scan_qr/scan_qr_bloc.dart';

// Widgets extraídos
import 'widgets/widgets.dart';
import 'package:qr_cosmo_app/core/utils/date_formatter.dart';

class ScanQRScreen extends StatelessWidget {
  const ScanQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScanQrBloc>(),
      child: const _ScanQRView(),
    );
  }
}

class _ScanQRView extends StatefulWidget {
  const _ScanQRView();

  @override
  State<_ScanQRView> createState() => _ScanQRViewState();
}

class _ScanQRViewState extends State<_ScanQRView> {
  late final MobileScannerController _cameraController;

  // Subscripciones a streams del Bloc (side effects)
  StreamSubscription<ScanQrValidationMessage>? _validationSubscription;
  StreamSubscription<ScanQrNavigation>? _navigationSubscription;

  // Estado local de UI (solo para control de cámara)
  int _scannerKey = 0;
  final TextEditingController _guestCountController = TextEditingController();
  FocusNode? _guestCountFocusNode;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController();
    _guestCountController.text = '1';
    _guestCountFocusNode = FocusNode();

    // Configurar usuario actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCurrentUser();
      _setupSideEffectStreams();
    });
  }

  void _setupCurrentUser() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ScanQrBloc>().setCurrentUser(authState.user.id, authState.user.name);
    }
  }

  void _setupSideEffectStreams() {
    final bloc = context.read<ScanQrBloc>();

    _validationSubscription = bloc.validationStream.listen(_onValidationMessage);
    _navigationSubscription = bloc.navigationStream.listen(_onNavigation);
  }

  @override
  void dispose() {
    _validationSubscription?.cancel();
    _navigationSubscription?.cancel();

    try {
      _cameraController.stop();
    } catch (e) {
      // Ignorar errores
    }
    _cameraController.dispose();
    _guestCountController.dispose();
    _guestCountFocusNode?.dispose();
    _guestCountFocusNode = null;
    super.dispose();
  }

  // =====================================================
  // HANDLERS DE STREAMS (side effects)
  // =====================================================

  void _onValidationMessage(ScanQrValidationMessage message) {
    if (!mounted) return;

    final color = message.type == ValidationMessageType.error
        ? AppColors.error
        : AppColors.warning;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.message),
        backgroundColor: color,
      ),
    );
  }

  void _onNavigation(ScanQrNavigation navigation) {
    switch (navigation) {
      case ScanQrNavigateToHome():
        _navigateToHome();
    }
  }

  // =====================================================
  // CONTROL DE CÁMARA
  // =====================================================

  Future<void> _stopCamera() async {
    try {
      await _cameraController.stop();
    } catch (e) {
      // Ignorar
    }
  }

  Future<void> _restartCamera() async {
    _guestCountFocusNode?.unfocus();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _scannerKey++;
      _guestCountController.text = '1';
    });

    try {
      await _cameraController.start();
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {});
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        try {
          await _cameraController.start();
        } catch (startError) {
          // Ignorar
        }
      }
    }
  }

  Future<void> _stopCameraAndShowSuccessDialog(ScanQrSuccess state) async {
    await _stopCamera();
    if (!mounted) return;

    await showScanSuccessDialog(
      context: context,
      guestData: GuestDisplayData(
        name: state.guestName,
        accessTypeLabel: state.accessTypeLabel,
      ),
      onAccept: () => context.read<ScanQrBloc>().add(const SuccessDialogAccepted()),
    );
  }

  Future<void> _stopCameraAndShowErrorDialog(ScanQrError state) async {
    await _stopCamera();
    if (!mounted) return;

    await showScanErrorDialog(
      context: context,
      message: state.message,
      onAccept: () => context.read<ScanQrBloc>().add(const ErrorDialogAccepted()),
    );
  }

  // =====================================================
  // NAVEGACIÓN
  // =====================================================

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // =====================================================
  // HANDLERS DE EVENTOS DE UI
  // =====================================================

  void _onDetect(BarcodeCapture capture) {
    final bloc = context.read<ScanQrBloc>();
    final state = bloc.state;
    // Solo procesar si está en idle
    if (state is! ScanQrIdle) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final qrCode = barcodes.first.rawValue ?? '';
    if (qrCode.isEmpty) return;

    bloc.add(QrCodeDetected(qrCode));
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScanQrBloc, ScanQrState>(
      listener: (context, state) {
        // Sincronizar controlador de cantidad cuando cambia el estado
        if (state is ScanQrInvitationInput) {
          _guestCountController.text = state.guestCount.toString();
        }

        // Manejar transiciones de cámara
        switch (state) {
          case ScanQrIdle():
            _restartCamera();
          case ScanQrProcessing():
            break;
          case ScanQrSuccess():
            _stopCameraAndShowSuccessDialog(state);
          case ScanQrError():
            _stopCameraAndShowErrorDialog(state);
          case ScanQrInvitationInput():
            _stopCamera();
        }
      },
      child: BlocBuilder<ScanQrBloc, ScanQrState>(
        builder: (context, state) {
          final showScanner = state is ScanQrIdle || state is ScanQrProcessing;

          return Scaffold(
            appBar: appAppBar(
              context: context,
              title: 'Escanear QR',
              actions: [
                if (showScanner)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flash_on_rounded, size: 20),
                    ),
                    onPressed: () => _cameraController.toggleTorch(),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildBody(state),
          );
        },
      ),
    );
  }

  Widget _buildBody(ScanQrState state) {
    switch (state) {
      case ScanQrIdle():
      case ScanQrProcessing():
        return _buildScannerView(isProcessing: state is ScanQrProcessing);
      case ScanQrInvitationInput():
        return _buildGuestCountView(state);
      case ScanQrSuccess():
      case ScanQrError():
        // Estos estados muestran diálogos, no vistas
        return const SizedBox.shrink();
    }
  }

  Widget _buildScannerView({required bool isProcessing}) {
    return Stack(
      children: [
        // Cámara
        MobileScanner(
          key: ValueKey(_scannerKey),
          controller: _cameraController,
          onDetect: _onDetect,
        ),

        // Overlay oscuro con recorte
        Container(
          decoration: ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: AppColors.primary,
              borderRadius: 16,
              borderLength: 32,
              borderWidth: 4,
              cutOutSize: MediaQuery.of(context).size.width * 0.75,
              overlayColor: AppColors.background.withValues(alpha: 0.8),
            ),
          ),
        ),

        // Instrucciones
        const Positioned(
          bottom: 100,
          left: 24,
          right: 24,
          child: ScannerInstructions(),
        ),

        // Loading overlay
        if (isProcessing)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildGuestCountView(ScanQrInvitationInput state) {
    final bloc = context.read<ScanQrBloc>();

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === INFO DE LA INVITACIÓN ===
              InvitationInfoCard(
                name: state.guestName,
                validUntil: state.validUntilFormatted != null
                    ? _parseDate(state.validUntilFormatted!)
                    : null,
                createdByName: state.createdByName,
                maxUses: state.maxUses,
                remainingUses: state.remainingUses,
                lastUsedDate: state.lastUsedDateFormatted != null
                    ? _parseDateTime(state.lastUsedDateFormatted!)
                    : null,
                formatDate: formatDate,
                formatDateTime: formatDateTime,
                remainingUsesColor: state.remainingUsesColor,
              ),
              const SizedBox(height: 20),

              // === SELECTOR DE CANTIDAD ===
              GuestCountSelector(
                guestCount: state.guestCount,
                maxCount: state.remainingUses > 0
                    ? state.remainingUses
                    : state.lastScanCount,
                controller: _guestCountController,
                focusNode: _guestCountFocusNode,
                onDecrement: state.guestCount > 1
                    ? () => bloc.add(const GuestCountDecremented())
                    : null,
                onIncrement: state.guestCount < (state.remainingUses > 0 ? state.remainingUses : state.lastScanCount)
                    ? () => bloc.add(const GuestCountIncremented())
                    : null,
                onChanged: (value) {
                  final count = int.tryParse(value) ?? 1;
                  bloc.add(GuestCountChanged(count));
                },
              ),
              const SizedBox(height: 32),

              // === BOTONES DE ACCIÓN ===
              ConfirmEntryButton(
                isProcessing: state.isConfirming,
                onPressed: () => bloc.add(const ConfirmGuestEntry()),
              ),
              const SizedBox(height: 12),

              CancelButton(
                onPressed: () => bloc.add(const ScanAgainRequested()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers para parsear fechas desde strings formateados
  DateTime? _parseDate(String formatted) {
    try {
      final parts = formatted.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      // Ignorar
    }
    return null;
  }

  DateTime? _parseDateTime(String formatted) {
    try {
      final dateParts = formatted.split(' ');
      if (dateParts.length == 2) {
        final date = _parseDate(dateParts[0]);
        if (date != null) {
          final timeParts = dateParts[1].split(':');
          if (timeParts.length == 2) {
            return DateTime(
              date.year,
              date.month,
              date.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
          }
        }
      }
    } catch (e) {
      // Ignorar
    }
    return null;
  }
}
