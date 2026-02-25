import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_cosmo_app/presentation/utils/utils.dart';
import 'package:qr_cosmo_app/domain/domain.dart';
import 'package:qr_cosmo_app/presentation/theme/theme.dart';
import 'package:qr_cosmo_app/presentation/widgets/widgets.dart';
import 'package:qr_cosmo_app/presentation/presentation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureAdminPassword = true;
  UserRole _selectedRole = UserRole.reader;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: _selectedRole,
          adminPassword: _adminPasswordController.text.trim().isNotEmpty
              ? _adminPasswordController.text.trim()
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          AppSnackbar.error(context, state.message);
        } else if (state is AuthAuthenticated) {
          AppSnackbar.success(context, '¡Cuenta creada exitosamente!');
          // Cerrar la pantalla de registro y volver
          // El AuthGate se encargará de mostrar HomeScreen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Crear Cuenta'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Name field
                  AppTextField(
                    controller: _nameController,
                    label: 'Nombre completo',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu nombre';
                      }
                      if (value.length < 2) {
                        return 'El nombre debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu email';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  AppTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Admin password field (only shown for generator/admin roles)
                  if (_selectedRole.requiresAdminValidation) ...[
                    AppTextField(
                      controller: _adminPasswordController,
                      label: 'Contraseña de Administrador',
                      icon: Icons.admin_panel_settings_outlined,
                      fillColor: Colors.orange.withValues(alpha: 0.1),
                      obscureText: _obscureAdminPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureAdminPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureAdminPassword = !_obscureAdminPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (_selectedRole.requiresAdminValidation) {
                          if (value == null || value.isEmpty) {
                            return 'Se requiere contraseña de administrador para este rol';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Role selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rol del usuario',
                          style: AppTextStyles.subtitleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...UserRole.values.map((role) => Theme(
                              data: Theme.of(context).copyWith(
                                unselectedWidgetColor: AppColors.textSecondary,
                              ),
                              child: RadioListTile<UserRole>(
                                title: Text(
                                  role.displayName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  _getRoleDescription(role),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                value: role,
                                groupValue: _selectedRole,
                                activeColor: AppColors.primary,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (UserRole? value) {
                                  setState(() {
                                    _selectedRole = value!;
                                    // Limpiar el campo de contraseña de administrador cuando cambie el rol
                                    if (!_selectedRole.requiresAdminValidation) {
                                      _adminPasswordController.clear();
                                    }
                                  });
                                },
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return PrimaryActionButton(
                        onPressed: _handleRegister,
                        label: 'Crear Cuenta',
                        isLoading: isLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.generator:
        return 'Puede generar códigos QR para invitados (requiere contraseña de administrador)';
      case UserRole.reader:
        return 'Solo puede escanear códigos QR en la entrada (rol por defecto)';
      case UserRole.admin:
        return 'Acceso completo: generar, leer y ver estadísticas (requiere contraseña de administrador)';
    }
  }
}
