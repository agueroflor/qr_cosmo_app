// lib/screens/generate_invitation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_cosmo_app/core/di/injection.dart';
import 'package:qr_cosmo_app/domain/entities/invitation_validity_type.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import 'package:qr_cosmo_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/generate_invitation/generate_invitation_cubit.dart';
import 'package:qr_cosmo_app/presentation/theme/app_button_styles.dart';
import 'package:qr_cosmo_app/presentation/theme/app_text_styles.dart';
import 'package:qr_cosmo_app/presentation/utils/snackbar_helper.dart';
import 'package:qr_cosmo_app/presentation/widgets/buttons/primary_action_button.dart';
import 'package:qr_cosmo_app/core/services/share_service.dart';
import '../widgets/qr_with_logo_widget.dart';
import '../widgets/info_row_widget.dart';
import '../widgets/app/app_app_bar.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

class GenerateInvitationScreen extends StatelessWidget {
  const GenerateInvitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final canGenerate = authState is AuthAuthenticated && authState.canGenerateQR;
        if (!canGenerate) {
          return Scaffold(
            appBar: appAppBar(context: context, title: 'Generar Invitación'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.red),
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
                    'No tienes permisos para generar invitaciones',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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

        return BlocProvider(
          create: (_) => getIt<GenerateInvitationCubit>(),
          child: const _GenerateInvitationView(),
        );
      },
    );
  }
}

/// Vista interna con el formulario y la lógica de UI
class _GenerateInvitationView extends StatefulWidget {
  const _GenerateInvitationView();

  @override
  State<_GenerateInvitationView> createState() => _GenerateInvitationViewState();
}

class _GenerateInvitationViewState extends State<_GenerateInvitationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usesController = TextEditingController(text: '5');
  DateTime? _selectedDate;
  InvitationValidityType _selectedValidityType = InvitationValidityType.operationalDay;

  @override
  void dispose() {
    _nameController.dispose();
    _usesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final bool isOperationalDay =
        _selectedValidityType == InvitationValidityType.operationalDay;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _findNextValidDate(DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      selectableDayPredicate: isOperationalDay
          ? (DateTime date) {
              // Solo permitir jueves, viernes y sábado
              return date.weekday == DateTime.thursday ||
                  date.weekday == DateTime.friday ||
                  date.weekday == DateTime.saturday;
            }
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        if (_selectedValidityType == InvitationValidityType.expirationDate) {
          _selectedDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        } else {
          _selectedDate = DateTime(picked.year, picked.month, picked.day);
        }
      });
    }
  }

  /// Encuentra el próximo día válido desde la fecha dada
  DateTime _findNextValidDate(DateTime from) {
    if (_selectedValidityType != InvitationValidityType.operationalDay) {
      return from;
    }
    var date = from;
    while (date.weekday != DateTime.thursday &&
        date.weekday != DateTime.friday &&
        date.weekday != DateTime.saturday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  void _onGeneratePressed() {
    if (!_formKey.currentState!.validate()) return;

    // Validar que se haya seleccionado fecha si el tipo lo requiere
    if (_selectedValidityType != InvitationValidityType.unlimited &&
        _selectedDate == null) {
      AppSnackbar.error(
        context,
        _selectedValidityType == InvitationValidityType.operationalDay
            ? 'Debes seleccionar la noche para la invitación'
            : 'Debes seleccionar una fecha límite',
      );
      return;
    }

    final authState = context.read<AuthCubit>().state as AuthAuthenticated;
    final currentUser = authState.user;

    context.read<GenerateInvitationCubit>().generateInvitation(
      name: _nameController.text,
      maxUses: int.parse(_usesController.text.trim()),
      validityType: _selectedValidityType,
      validForDate: _selectedValidityType != InvitationValidityType.unlimited
          ? _selectedDate
          : null,
      userId: currentUser.id,
      userName: currentUser.name,
    );
  }

  void _onResetPressed() {
    _nameController.clear();
    _usesController.text = '5';
    setState(() {
      _selectedDate = null;
      _selectedValidityType = InvitationValidityType.operationalDay;
    });
    context.read<GenerateInvitationCubit>().resetForm();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getInfoBoxText() {
    final uses = _usesController.text.isEmpty ? 'X' : _usesController.text;
    return switch (_selectedValidityType) {
      InvitationValidityType.operationalDay =>
        'Se generará 1 QR para $uses personas. Solo será válido la noche seleccionada.',
      InvitationValidityType.expirationDate =>
        'Se generará 1 QR para $uses personas. Será válido hasta la fecha límite seleccionada.',
      InvitationValidityType.unlimited =>
        'Se generará 1 QR para $uses personas. No tiene vencimiento, solo se agota al usar todos los ingresos.',
    };
  }

  String _getValidityDisplayText(GuestModel invitation) {
    return switch (invitation.validityType) {
      InvitationValidityType.operationalDay => invitation.validForDate != null
          ? 'Noche del ${_formatDate(invitation.validForDate!)}'
          : 'Fecha específica',
      InvitationValidityType.expirationDate => invitation.validForDate != null
          ? 'Hasta ${_formatDate(invitation.validForDate!)}'
          : 'Con fecha límite',
      InvitationValidityType.unlimited => 'Sin vencimiento',
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GenerateInvitationCubit, GenerateInvitationState>(
      listener: (context, state) {
        if (state is GenerateInvitationSuccess) {
          AppSnackbar.success(context, '¡Invitación generada exitosamente!');
        } else if (state is GenerateInvitationError) {
          AppSnackbar.error(context, 'Error: ${state.message}');
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: appAppBar(
            context: context,
            title: 'Generar Invitación',
            actions: [
              if (state is GenerateInvitationSuccess)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _onResetPressed,
                  tooltip: 'Generar nueva invitación',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (state is GenerateInvitationSuccess) ...[
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

  Widget _buildFormSection(GenerateInvitationState state) {
    final isLoading = state is GenerateInvitationLoading;

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
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la invitación',
                prefixIcon: const Icon(Icons.label),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: 'Ej: Invitación Viernes',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un nombre para la invitación';
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Cantidad de usos
            TextFormField(
              controller: _usesController,
              decoration: InputDecoration(
                labelText: 'Cantidad de invitados',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                hintText: 'Ej: 5',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa la cantidad de invitados';
                }
                final number = int.tryParse(value);
                if (number == null || number < 1) {
                  return 'Debe ser un número mayor a 0';
                }
                if (number > 100) {
                  return 'Máximo 100 invitados por QR';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tipo de validez
            const Text(
              'Tipo de validez',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<InvitationValidityType>(
                segments: InvitationValidityType.values.map((type) {
                  return ButtonSegment<InvitationValidityType>(
                    value: type,
                    label: Text(
                      type.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                selected: {_selectedValidityType},
                onSelectionChanged: (Set<InvitationValidityType> newSelection) {
                  setState(() {
                    _selectedValidityType = newSelection.first;
                    _selectedDate = null; // Reset fecha al cambiar tipo
                  });
                },
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selector de fecha (condicional)
            if (_selectedValidityType != InvitationValidityType.unlimited) ...[
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? (_selectedValidityType == InvitationValidityType.operationalDay
                                  ? 'Seleccionar noche (jue/vie/sáb)'
                                  : 'Seleccionar fecha límite')
                              : (_selectedValidityType == InvitationValidityType.operationalDay
                                  ? 'Noche del ${_formatDate(_selectedDate!)}'
                                  : 'Válida hasta: ${_formatDate(_selectedDate!)}'),
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null
                              ? Colors.grey[600]
                              : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Info box dinámico
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getInfoBoxText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Generate button
            PrimaryActionButton(
              onPressed: _onGeneratePressed,
              label: 'Generar',
              isLoading: isLoading,
              icon: const Icon(Icons.card_giftcard),
              style: AppButtonStyles.success(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(GenerateInvitationSuccess state) {
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
            'Invitación Generada!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 10),

          // Invitation info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoRow(label: 'Nombre:', value: state.invitation.name),
                const SizedBox(height: 6),
                InfoRow(label: 'Cantidad:', value: '${state.invitation.maxUses} invitados'),
                const SizedBox(height: 6),
                InfoRow(label: 'Validez:', value: _getValidityDisplayText(state.invitation)),
                const SizedBox(height: 6),
                //InfoRow(label: 'Usos restantes:', value: '${state.invitation.remainingUses}'),
                //const SizedBox(height: 6),
                InfoRow(label: 'Creado por:', value: state.invitation.createdByName),
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
                child: ElevatedButton(
                  onPressed: () {
                    ShareService.showShareOptions(
                      qrCode: state.qrCode,
                      guestName: state.invitation.name,
                      guestDni: state.invitation.dni,
                      context: context,
                      isInvitation: true,
                    );
                  },
                  style: AppButtonStyles.success(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Compartir',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

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
                              'Generar Otra',
                              style: TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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

