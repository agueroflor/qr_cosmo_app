// lib/screens/manage_invitations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_cosmo_app/core/di/injection.dart';
import 'package:qr_cosmo_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:qr_cosmo_app/presentation/cubits/invitations/manage_invitations_cubit.dart';
import 'package:qr_cosmo_app/presentation/utils/snackbar_helper.dart';
import 'package:qr_cosmo_app/presentation/utils/dialog_helper.dart';
import 'package:qr_cosmo_app/data/models/guest_model.dart';
import '../widgets/app/app_app_bar.dart';
import '../widgets/app/app_filter_chip.dart';
import '../widgets/info_row_widget.dart';
import 'package:qr_cosmo_app/presentation/theme/app_colors.dart';

class ManageInvitationsScreen extends StatelessWidget {
  const ManageInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ManageInvitationsCubit>()..loadInvitations(),
      child: const _ManageInvitationsView(),
    );
  }
}

/// Vista interna que maneja el estado local de filtros y escucha el Cubit
class _ManageInvitationsView extends StatefulWidget {
  const _ManageInvitationsView();

  @override
  State<_ManageInvitationsView> createState() => _ManageInvitationsViewState();
}

class _ManageInvitationsViewState extends State<_ManageInvitationsView> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, valid, used_up, inactive
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelectAll(List<GuestModel> filteredInvitations, String? currentUserId) {
    final ownIds = filteredInvitations
        .where((i) => i.isOwner(currentUserId))
        .map((e) => e.id)
        .toSet();
    final allSelected = ownIds.every((id) => _selectedIds.contains(id));
    setState(() {
      if (allSelected) {
        _selectedIds.removeAll(ownIds);
      } else {
        _selectedIds.addAll(ownIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appAppBar(
        context: context,
        title: 'Invitaciones',
        actions: [
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.delete),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? 'Salir de selección' : 'Seleccionar invitaciones',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ManageInvitationsCubit>().refresh(),
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: BlocConsumer<ManageInvitationsCubit, ManageInvitationsState>(
        listener: (context, state) {
          // Mostrar SnackBar en caso de error
          if (state is ManageInvitationsError) {
            AppSnackbar.error(context, state.message);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Filtros y búsqueda
              _buildFiltersSection(),

              // Estadísticas rápidas
              _buildStatsSection(state),

              const Divider(height: 1),

              // Lista de invitaciones
              Expanded(
                child: _buildInvitationsList(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Filtros de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Filtrar:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                AppFilterChip(
                  label: 'Todas',
                  isSelected: _filterStatus == 'all',
                  onTap: () => setState(() => _filterStatus = 'all'),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Activas',
                  isSelected: _filterStatus == 'valid',
                  onTap: () => setState(() => _filterStatus = 'valid'),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Agotadas',
                  isSelected: _filterStatus == 'used_up',
                  onTap: () => setState(() => _filterStatus = 'used_up'),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Inactivas',
                  isSelected: _filterStatus == 'inactive',
                  onTap: () => setState(() => _filterStatus = 'inactive'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ManageInvitationsState state) {
    int total = 0;
    int active = 0;
    int exhausted = 0;
    int inactive = 0;

    if (state is ManageInvitationsLoaded) {
      total = state.totalCount;
      active = state.activeCount;
      exhausted = state.exhaustedCount;
      inactive = state.inactiveCount;
    } else if (state is ManageInvitationsOperationInProgress) {
      final invitations = state.invitations;
      total = invitations.length;
      active = invitations.where((i) => i.isValidInvitation).length;
      exhausted = invitations.where((i) => !i.hasRemainingUses && i.maxUses != null).length;
      inactive = invitations.where((i) => !i.isActive).length;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            label: 'Total',
            value: total.toString(),
            color: Colors.blue,
          ),
          _StatChip(
            label: 'Activas',
            value: active.toString(),
            color: Colors.green,
          ),
          _StatChip(
            label: 'Agotadas',
            value: exhausted.toString(),
            color: Colors.red,
          ),
          _StatChip(
            label: 'Inactivas',
            value: inactive.toString(),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsList(ManageInvitationsState state) {
    if (state is ManageInvitationsInitial || state is ManageInvitationsLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Cargando invitaciones...'),
          ],
        ),
      );
    }

    List<GuestModel> invitations = [];
    if (state is ManageInvitationsLoaded) {
      invitations = state.invitations;
    } else if (state is ManageInvitationsOperationInProgress) {
      invitations = state.invitations;
    } else if (state is ManageInvitationsError) {
      // Si hay error pero no tenemos datos previos, mostrar mensaje de error
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar invitaciones',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.read<ManageInvitationsCubit>().refresh(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Filtrar invitaciones localmente
    final filteredInvitations = ManageInvitationsCubit.filterInvitations(
      invitations,
      _searchQuery,
      _filterStatus,
    );

    if (filteredInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterStatus != 'all'
                  ? 'No se encontraron invitaciones'
                  : 'No hay invitaciones',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterStatus != 'all'
                  ? 'Intenta cambiar los filtros'
                  : 'Las invitaciones generadas aparecerán aquí',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
        final listContent = ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredInvitations.length,
          itemBuilder: (context, index) {
            final invitation = filteredInvitations[index];
            final canDelete = invitation.isOwner(currentUserId);
            return Dismissible(
              key: ValueKey(invitation.id),
              direction: canDelete ? DismissDirection.endToStart : DismissDirection.none,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 32),
              ),
              confirmDismiss: (_) async {
                if (!canDelete) return false;
                final confirmed = await _showDeleteConfirmationDialog(invitation);
                if (confirmed && context.mounted) _deleteInvitation(invitation);
                return confirmed;
              },
              onDismissed: (_) {},
              child: _InvitationCard(
                invitation: invitation,
                currentUserId: currentUserId,
                statusText: ManageInvitationsCubit.getStatusText(invitation),
                statusColor: _getInvitationStatusColor(invitation),
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedIds.contains(invitation.id),
                onTapToggle: invitation.isOwner(currentUserId)
                    ? () {
                        setState(() {
                          if (_selectedIds.contains(invitation.id)) {
                            _selectedIds.remove(invitation.id);
                          } else {
                            _selectedIds.add(invitation.id);
                          }
                        });
                      }
                    : null,
              ),
            );
          },
        );

        if (_isSelectionMode && filteredInvitations.isNotEmpty) {
          return Column(
            children: [
              _buildSelectionBar(filteredInvitations, currentUserId),
              Expanded(child: listContent),
            ],
          );
        }
        return listContent;
      },
    );
  }

  Widget _buildSelectionBar(List<GuestModel> filteredInvitations, String? currentUserId) {
    final ownInvitations =
        filteredInvitations.where((i) => i.isOwner(currentUserId)).toList();
    final allOwnSelected = ownInvitations.isNotEmpty &&
        ownInvitations.every((i) => _selectedIds.contains(i.id));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => _toggleSelectAll(filteredInvitations, currentUserId),
            icon: Icon(allOwnSelected ? Icons.deselect : Icons.select_all),
            label: Text(allOwnSelected ? 'Deseleccionar todas' : 'Seleccionar todas'),
          ),
          const Spacer(),
          if (_selectedIds.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _showDeleteMultipleConfirmation(currentUserId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: Text('Eliminar (${_selectedIds.length})'),
            ),
        ],
      ),
    );
  }

  Future<void> _showDeleteMultipleConfirmation(String? currentUserId) async {
    if (currentUserId == null) {
      AppSnackbar.error(context, 'Usuario no autenticado');
      return;
    }
    final idsToDelete = _selectedIds.toList();
    if (idsToDelete.isEmpty) return;

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar invitaciones',
      message: '¿Eliminar ${idsToDelete.length} invitación(es)? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDanger: true,
    );
    if (confirmed && context.mounted) {
      context.read<ManageInvitationsCubit>().deleteInvitations(idsToDelete, currentUserId);
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Color _getInvitationStatusColor(GuestModel invitation) {
    final status = ManageInvitationsCubit.getStatusText(invitation);
    const statusColors = {
      'INACTIVA': Colors.grey,
      'AGOTADA': Colors.red,
      'EXPIRADA': Colors.deepOrange,
      'ACTIVA': Colors.green,
    };
    return statusColors[status] ?? Colors.grey;
  }

  Future<bool> _showDeleteConfirmationDialog(GuestModel invitation) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar',
      message: '¿Estás seguro de que quieres eliminar esta invitación?',
      confirmLabel: 'Eliminar',
      isDanger: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Estás seguro de que quieres eliminar esta invitación?'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de la invitación:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text('• Nombre: ${invitation.name}'),
                if (invitation.maxUses != null)
                  Text('• Usos: ${invitation.totalVisits}/${invitation.maxUses}'),
                if (invitation.validUntil != null)
                  Text('• Válida hasta: ${_formatDateOnly(invitation.validUntil!)}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Esta acción no se puede deshacer y eliminará:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text('• El código QR de la invitación'),
          const Text('• Todas las visitas registradas'),
          const Text('• El historial completo'),
        ],
      ),
    );
    return confirmed;
  }

  void _deleteInvitation(GuestModel invitation) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      AppSnackbar.error(context, 'Usuario no autenticado');
      return;
    }

    context.read<ManageInvitationsCubit>().deleteInvitation(
      invitation.id,
      authState.user.id,
    );
  }

  String _formatDateOnly(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final GuestModel invitation;
  final String statusText;
  final Color statusColor;
  final String? currentUserId;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onTapToggle;

  const _InvitationCard({
    required this.invitation,
    required this.statusText,
    required this.statusColor,
    this.currentUserId,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTapToggle,
  });

  @override
  Widget build(BuildContext context) {
    final content = Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelectionMode && invitation.isOwner(currentUserId))
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onTapToggle != null ? (_) => onTapToggle!() : null,
                      activeColor: AppColors.primary,
                    ),
                  ),
                Expanded(
                  child: Text(
                    invitation.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (invitation.maxUses != null)
              InfoRow(
                label: 'Usos:',
                value: '${invitation.totalVisits} / ${invitation.maxUses} (${invitation.remainingUses} restantes)',
              ),
            if (invitation.validUntil != null)
              InfoRow(label: 'Fecha ref.:', value: _formatDateOnly(invitation.validUntil!)),
            InfoRow(label: 'Creado por:', value: invitation.createdByName),
            InfoRow(label: 'Fecha creación:', value: _formatDate(invitation.createdAt)),
            if (invitation.lastUsedDate != null)
              InfoRow(label: 'Último uso:', value: _formatDate(invitation.lastUsedDate!)),
          ],
        ),
      ),
    );

    return content;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateOnly(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

