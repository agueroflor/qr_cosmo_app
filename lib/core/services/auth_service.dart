import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_cosmo_app/data/models/user_model.dart';
import 'package:qr_cosmo_app/domain/entities/user_role.dart';

@Deprecated(
  'Legacy service — use AuthCubit + AuthRepository instead. '
  'Kept temporarily for migration reference.',
)
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get user => _auth.currentUser;
  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService() {
    // Escuchar cambios en el estado de autenticación
    _auth.authStateChanges().listen(_onAuthStateChanged);
    // Cargar datos iniciales si ya hay un usuario autenticado
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_auth.currentUser != null) {
      await _loadCurrentUserModel();
      notifyListeners();
    }
  }

  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      await _loadCurrentUserModel();
    } else {
      _currentUserModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadCurrentUserModel() async {
    if (user == null) return;
    
    try {
      debugPrint('Loading user model for UID: ${user!.uid}');
      final doc = await _firestore.collection('users').doc(user!.uid).get();
      debugPrint('Document exists: ${doc.exists}');
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        debugPrint('Document data: $data');
        _currentUserModel = UserModel.fromMap(data, doc.id);
        debugPrint('User model loaded: ${_currentUserModel?.name}');
      } else {
        debugPrint('No user document found in Firestore');
        _currentUserModel = null;
      }
    } catch (e) {
      debugPrint('Error loading user model: $e');
      _currentUserModel = null;
    }
  }

  // Registrar nuevo usuario
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? adminPassword,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('Starting registration for email: $email, role: ${role.name}');

      // Validar acceso privilegiado si es necesario
      // NOTA: Este servicio legacy no usa UseCases.
      // La validación real se hace en AuthCubit via ValidateAdminAccessUseCase.
      if (role.requiresAdminValidation) {
        if (adminPassword == null || adminPassword.isEmpty) {
          return 'Se requiere código de acceso para este rol';
        }
      }

      // Crear usuario en Firebase Auth
      debugPrint('Creating user in Firebase Auth...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('User created successfully: ${credential.user?.uid}');

      // Crear documento de usuario en Firestore
      if (credential.user != null) {
        final newUser = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
        );

        debugPrint('Saving user to Firestore: ${newUser.toMap()}');
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        // Establecer el modelo de usuario actual
        _currentUserModel = newUser;
        debugPrint('User registration completed successfully');
        debugPrint('User is now logged in: ${_currentUserModel?.name}');
        
        // Notificar a los listeners que el usuario está logueado
        notifyListeners();
      }

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          return 'La contraseña es muy débil';
        case 'email-already-in-use':
          return 'El email ya está en uso';
        case 'invalid-email':
          return 'El email no es válido';
        default:
          return 'Error de registro: ${e.message}';
      }
    } catch (e) {
      debugPrint('Unexpected error during registration: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return 'Error inesperado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Iniciar sesión
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Usuario no encontrado';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'invalid-email':
          return 'Email inválido';
        case 'user-disabled':
          return 'Usuario deshabilitado';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde';
        default:
          return 'Error de inicio de sesión: ${e.message}';
      }
    } catch (e) {
      return 'Error inesperado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      debugPrint('Signing out user...');
      await _auth.signOut();
      
      _currentUserModel = null;
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verificar permisos
  bool canGenerateQR() {
    return _currentUserModel?.role.canGenerateQR ?? false;
  }

  bool canReadQR() {
    return _currentUserModel?.role.canReadQR ?? false;
  }

  bool canViewStatistics() {
    return _currentUserModel?.role.canViewStatistics ?? false;
  }
}
