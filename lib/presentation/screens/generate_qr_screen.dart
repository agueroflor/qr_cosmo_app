// lib/screens/generate_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_cosmo_app/presentation/theme/app_button_styles.dart';
import 'package:qr_cosmo_app/presentation/theme/app_text_styles.dart';
import 'package:qr_cosmo_app/core/di/injection.dart';
import 'package:qr_cosmo_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/generate_qr/generate_qr_cubit.dart';
import 'package:qr_cosmo_app/presentation/utils/snackbar_helper.dart';
import 'package:qr_cosmo_app/presentation/widgets/buttons/primary_action_button.dart';
import 'package:qr_cosmo_app/core/services/share_service.dart';
import '../widgets/qr_with_logo_widget.dart';
import '../widgets/info_row_widget.dart';
import '../widgets/app/app_app_bar.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

class GenerateQRScreen extends StatelessWidget {
  const GenerateQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // Verificar permisos antes de mostrar la pantalla
        final canGenerate = authState is AuthAuthenticated && authState.canGenerateQR;
        if (!canGenerate) {
          return _buildAccessDeniedScreen(context);
        }

        return BlocProvider(
          create: (_) => getIt<GenerateQrCubit>(),
          child: const _GenerateQrView(),
        );
      },
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context) {
    return Scaffold(
      appBar: appAppBar(context: context, title: 'Generar QR'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.block,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Acceso Denegado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tienes permisos para generar códigos QR',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista interna con el formulario y la lógica de UI
class _GenerateQrView extends StatefulWidget {
  const _GenerateQrView();

  @override
  State<_GenerateQrView> createState() => _GenerateQrViewState();
}

class _GenerateQrViewState extends State<_GenerateQrView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dniController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  void _onGeneratePressed() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthCubit>().state as AuthAuthenticated;
    final currentUser = authState.user;

    context.read<GenerateQrCubit>().generateQr(
      name: _nameController.text,
      dni: _dniController.text,
      userId: currentUser.id,
      userName: currentUser.name,
    );
  }

  void _onResetPressed() {
    _nameController.clear();
    _dniController.clear();
    context.read<GenerateQrCubit>().resetForm();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GenerateQrCubit, GenerateQrState>(
      listener: (context, state) {
        if (state is GenerateQrSuccess) {
          AppSnackbar.success(context, '¡Código QR generado exitosamente!');
        } else if (state is GenerateQrError) {
          AppSnackbar.error(context, 'Error: ${state.message}');
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: appAppBar(
            context: context,
            title: 'Generar QR',
            actions: [
              if (state is GenerateQrSuccess)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _onResetPressed,
                  tooltip: 'Generar nuevo QR',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (state is GenerateQrSuccess) ...[
                  _buildResultSection(state),
                ] else ...[
                  _buildFormSection(state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormSection(GenerateQrState state) {
    final isLoading = state is GenerateQrLoading;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del Invitado',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 20),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el nombre del invitado';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // DNI field
            TextFormField(
              controller: _dniController,
              decoration: InputDecoration(
                labelText: 'DNI (sin puntos)',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: 'Ej: 12345678',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el DNI del invitado';
                }
                if (value.length < 7 || value.length > 8) {
                  return 'El DNI debe tener 7 u 8 dígitos';
                }
                if (!RegExp(r'^\d+$').hasMatch(value)) {
                  return 'El DNI solo debe contener números';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Generate button
            PrimaryActionButton(
              onPressed: _onGeneratePressed,
              label: 'Generar Código QR',
              isLoading: isLoading,
              icon: const Icon(Icons.qr_code),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(GenerateQrSuccess state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'QR Generado!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 10),

          // Guest info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoRow(label: 'Nombre:', value: state.guest.name),
                const SizedBox(height: 6),
                InfoRow(label: 'DNI:', value: state.guest.formattedDni),
                const SizedBox(height: 6),
                InfoRow(label: 'Creado por:', value: state.guest.createdByName),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: QRWithLogoWidget(
              qrCode: state.qrCode,
              size: 200.0,
              logoSize: 80.0,
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de compartir
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ShareService.showShareOptions(
                      qrCode: state.qrCode,
                      guestName: state.guest.name,
                      guestDni: state.guest.dni,
                      context: context,
                    );
                  },
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text('Compartir QR', style: TextStyle(fontSize: 14)),
                  style: AppButtonStyles.success(),
                ),
              ),
              const SizedBox(height: 10),

              // Botones de navegación
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onResetPressed,
                      style: AppButtonStyles.outlined().copyWith(
                        foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
                        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.primary)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Generar Otro',
                              style: TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: AppButtonStyles.primary(),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home, size: 18),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Volver',
                              style: TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

