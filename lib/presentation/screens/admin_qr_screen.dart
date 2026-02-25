import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_cosmo_app/presentation/theme/app_button_styles.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';
import 'package:qr_cosmo_app/presentation/theme/app_text_styles.dart';
import 'package:qr_cosmo_app/core/di/injection.dart';
import 'package:qr_cosmo_app/presentation/cubits/admin_guests/admin_guests_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:qr_cosmo_app/presentation/utils/snackbar_helper.dart';
import 'package:qr_cosmo_app/presentation/utils/dialog_helper.dart';
import 'package:qr_cosmo_app/core/services/share_service.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import '../widgets/widgets.dart';

class AdminQRScreen extends StatelessWidget {
  const AdminQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminGuestsCubit>()..loadGuests(),
      child: const _AdminQRView(),
    );
  }
}

class _AdminQRView extends StatefulWidget {
  const _AdminQRView();

  @override
  State<_AdminQRView> createState() => _AdminQRViewState();
}

class _AdminQRViewState extends State<_AdminQRView> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  List<GuestModel> _filterGuests(List<GuestModel> guests) {
    return guests.where((guest) {
      final matchesSearch = _searchQuery.isEmpty ||
          guest.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          guest.dni.contains(_searchQuery);

      final matchesStatus = _filterStatus == 'all' ||
          (_filterStatus == 'active' && guest.isActive) ||
          (_filterStatus == 'inactive' && !guest.isActive);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _onToggleStatus(GuestModel guest) {
    context.read<AdminGuestsCubit>().toggleStatus(guest.id, guest.isActive);
  }

  void _onDeleteGuest(GuestModel guest) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      AppSnackbar.error(context, 'Usuario no autenticado');
      return;
    }
    context.read<AdminGuestsCubit>().deleteGuest(guest.id, authState.user.id);
  }

  void _onUpdateGuestInfo(GuestModel guest, String newName, String newDni) {
    context.read<AdminGuestsCubit>().updateGuestInfo(guest.id, newName, newDni);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminGuestsCubit, AdminGuestsState>(
      listener: (context, state) {
        if (state is AdminGuestsError) {
          AppSnackbar.error(context, state.message);
          // Reload after showing error so the list stays visible
          context.read<AdminGuestsCubit>().loadGuests();
        }
      },
      builder: (context, state) {
        final guests = state is AdminGuestsLoaded ? state.guests : <GuestModel>[];
        final isLoading = state is AdminGuestsLoading;
        final filtered = _filterGuests(guests);

        return _buildScaffold(context, filtered, isLoading);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, List<GuestModel> filteredGuests, bool isLoading) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appAppBar(
        context: context,
        title: 'Administrar QR',
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded, size: 20),
            ),
            onPressed: () => context.read<AdminGuestsCubit>().refresh(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Búsqueda y filtros
          _buildSearchAndFilters(),
          // Lista
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : filteredGuests.isEmpty
                    ? const EmptyState(
                        icon: Icons.qr_code_rounded,
                        title: 'No hay invitados',
                        subtitle: 'Los QR generados aparecerán aquí',
                      )
                    : _buildGuestList(filteredGuests),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o DNI...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Filtros
          Row(
            children: [
              AppFilterChip(
                label: 'Todos',
                isSelected: _filterStatus == 'all',
                onTap: () => setState(() => _filterStatus = 'all'),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Activos',
                isSelected: _filterStatus == 'active',
                onTap: () => setState(() => _filterStatus = 'active'),
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: 'Pausados',
                isSelected: _filterStatus == 'inactive',
                onTap: () => setState(() => _filterStatus = 'inactive'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestList(List<GuestModel> filteredGuests) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filteredGuests.length,
          itemBuilder: (context, index) {
            final guest = filteredGuests[index];
            return _GuestCard(
              guest: guest,
              currentUserId: currentUserId,
              onToggleStatus: () => _onToggleStatus(guest),
              onShowDetails: () => _showDetailsSheet(guest),
              onEdit: () => _showEditDialog(guest),
              onDelete: () => _showDeleteConfirmationDialog(guest),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(GuestModel guest) {
    final nameController = TextEditingController(text: guest.name);
    final dniController = TextEditingController(text: guest.dni);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Título
                const Text(
                  'Editar Invitado',
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 24),
                // Nombre
                AppTextField(
                  controller: nameController,
                  label: 'Nombre completo',
                  icon: Icons.person_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    if (value.trim().length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // DNI
                AppTextField(
                  controller: dniController,
                  label: 'DNI',
                  icon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  counterText: '',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El DNI es obligatorio';
                    }
                    if (value.trim().length != 8 || !RegExp(r'^\d+$').hasMatch(value.trim())) {
                      return 'DNI debe tener 8 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        onTap: () => Navigator.pop(context),
                        label: 'Cancelar',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              _onUpdateGuestInfo(
                                guest,
                                nameController.text.trim(),
                                dniController.text.trim(),
                              );
                            }
                          },
                          style: AppButtonStyles.primary(),
                          child: const Text('Guardar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(GuestModel guest) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar QR',
      message: '¿Estás seguro de eliminar este QR?',
      confirmLabel: 'Eliminar',
      isDanger: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Estás seguro de eliminar este QR?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DNI: ${guest.formattedDni} • ${guest.totalVisits} visitas',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Esta acción eliminará el QR y todo su historial.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
    if (confirmed) {
      _onDeleteGuest(guest);
    }
  }

  void _showDetailsSheet(GuestModel guest) {
    final usedToday = guest.wasUsedOnDate(DateTime.now());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Título
            Row(
              children: [
                const Text(
                  'Detalles',
                  style: AppTextStyles.heading,
                ),
                const Spacer(),
                StatusBadge(
                  label: guest.isActive ? 'ACTIVO' : 'PAUSADO',
                  isPositive: guest.isActive,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Info
            InfoCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InfoRow(label: 'Nombre', value: guest.name, bold: true),
                  InfoRow(label: 'DNI', value: guest.formattedDni),
                  InfoRow(label: 'Visitas', value: guest.totalVisits.toString()),
                  if (guest.lastUsedDate != null) ...[
                    InfoRow(label: 'Último uso', value: _formatDate(guest.lastUsedDate!)),
                    InfoRow(
                      label: 'Usado hoy',
                      value: usedToday ? 'Sí' : 'No',
                      valueColor: usedToday ? AppColors.warning : null,
                    ),
                  ],
                  InfoRow(label: 'Creado por', value: guest.createdByName),
                  InfoRow(label: 'Fecha', value: _formatDate(guest.createdAt)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Acciones
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _onToggleStatus(guest);
                      },
                      icon: Icon(
                        guest.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      label: Text(guest.isActive ? 'Pausar' : 'Activar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: guest.isActive
                            ? AppColors.warning
                            : AppColors.success,
                        side: BorderSide(
                          color: guest.isActive
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ShareService.showShareOptions(
                          qrCode: guest.qrCode,
                          guestName: guest.name,
                          guestDni: guest.dni,
                          context: context,
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Compartir'),
                      style: AppButtonStyles.primary(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// =====================================================
// WIDGETS PRIVADOS
// =====================================================

class _GuestCard extends StatelessWidget {
  final GuestModel guest;
  final String? currentUserId;
  final VoidCallback onToggleStatus;
  final VoidCallback onShowDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GuestCard({
    required this.guest,
    required this.currentUserId,
    required this.onToggleStatus,
    required this.onShowDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onShowDetails,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guest.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'DNI: ${guest.formattedDni} • ${guest.totalVisits} visitas',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: guest.isActive ? 'ACTIVO' : 'PAUSADO',
                      isPositive: guest.isActive,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Acciones
                Row(
                  children: [
                    _ActionIcon(
                      icon: guest.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: guest.isActive ? AppColors.warning : AppColors.success,
                      onTap: onToggleStatus,
                    ),
                    const SizedBox(width: 8),
                    _ActionIcon(
                      icon: Icons.edit_rounded,
                      color: AppColors.primary,
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 8),
                    _ActionIcon(
                      icon: Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                      onTap: onShowDetails,
                    ),
                    if (guest.isOwner(currentUserId)) ...[
                      const SizedBox(width: 8),
                      _ActionIcon(
                        icon: Icons.delete_rounded,
                        color: AppColors.error,
                        onTap: onDelete,
                      ),
                    ],
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
