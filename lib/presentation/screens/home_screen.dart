import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_cosmo_app/presentation/utils/utils.dart';
import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/presentation/theme/theme.dart';
import 'package:qr_cosmo_app/presentation/screens/screens.dart';
import 'package:qr_cosmo_app/presentation/widgets/widgets.dart';
import 'package:qr_cosmo_app/presentation/presentation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final user = state.user;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header con logo y menú
                SliverToBoxAdapter(
                  child: _buildHeader(context, user.name),
                ),
                // Acciones principales
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: _buildActionGrid(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final roleDisplayName = state is AuthAuthenticated
            ? state.user.role.displayName
            : '';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Logo/nombre + menú
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del bar
                        const Text(
                          'COSMOPOLITAN',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'FLAIR BAR',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menú
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        _showLogoutDialog(context);
                      }
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.textSecondary),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                color: AppColors.error, size: 20),
                            SizedBox(width: 12),
                            Text('Cerrar Sesión'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Saludo al usuario
              Text(
                'Hola, $userName',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                roleDisplayName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionGrid(BuildContext context, AuthAuthenticated authState) {
    final List<Widget> actions = [];

    if (authState.canReadQR) {
      actions.add(
        ActionButton(
          title: 'Escanear QR',
          subtitle: 'Validar entrada',
          icon: Icons.qr_code_scanner_rounded,
          accentColor: AppColors.success,
          isLarge: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanQRScreen()),
          ),
        ),
      );
    }

    // Generar QR Personal
    if (authState.canGenerateQR) {
      actions.add(
        ActionButton(
          title: 'Generar QR',
          subtitle: 'QR personal',
          icon: Icons.qr_code_rounded,
          accentColor: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GenerateQRScreen()),
          ),
        ),
      );
    }

    // Generar Invitaciones
    if (authState.canGenerateQR) {
      actions.add(
        ActionButton(
          title: 'Invitaciones',
          subtitle: 'QR grupales',
          icon: Icons.group_add_rounded,
          accentColor: AppColors.neonBlue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const GenerateInvitationScreen()),
          ),
        ),
      );
    }

    // Gestionar Invitaciones
    if (authState.canGenerateQR) {
      actions.add(
        ActionButton(
          title: 'Gestionar',
          subtitle: 'Invitaciones',
          icon: Icons.edit_note_rounded,
          accentColor: AppColors.neonBlue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ManageInvitationsScreen()),
          ),
        ),
      );
    }

    // Administrar QR
    if (authState.canGenerateQR) {
      actions.add(
        ActionButton(
          title: 'Administrar',
          subtitle: 'QR personales',
          icon: Icons.admin_panel_settings_rounded,
          accentColor: AppColors.neonBlue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminQRScreen()),
          ),
        ),
      );
    }

    // Estadísticas
    /*if (authState.canViewStatistics) {
      actions.add(
        ActionButton(
          title: 'Estadísticas',
          subtitle: 'Métricas',
          icon: Icons.analytics_rounded,
          accentColor: AppColors.warning,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StatisticsScreen()),
          ),
        ),
      );
    }*/

    // Grid responsivo
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => actions[index],
        childCount: actions.length,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Cerrar Sesión',
      message: '¿Seguro que querés cerrar sesión?',
      confirmLabel: 'Cerrar Sesión',
      isDanger: true,
    );
    if (confirmed && context.mounted) {
      context.read<AuthCubit>().signOut();
    }
  }
}
