/**
 * Servicio de autenticación
 * Gestiona el login, registro, logout y estado del usuario
 */

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  
  AuthService() {
    // Escuchar cambios en el estado de autenticación
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  /**
   * Callback que se ejecuta cuando cambia el estado de autenticación
   */
  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    
    if (user != null) {
      // Verificar si completó el onboarding
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      _hasCompletedOnboarding = userDoc.data()?['onboardingCompleted'] ?? false;
    } else {
      _hasCompletedOnboarding = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /**
   * Registrar un nuevo usuario
   * @param email Email del usuario
   * @param password Contraseña
   * @param name Nombre completo
   * @param phone Teléfono
   * @param location Ubicación
   * @return String con error o null si fue exitoso
   */
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String location,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Actualizar el nombre de usuario
      await userCredential.user?.updateDisplayName(name);
      
      // Crear documento en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,
        'photoURL': null,
      });
      
      return null; // Sin errores
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'La contraseña es demasiado débil';
      } else if (e.code == 'email-already-in-use') {
        return 'Este email ya está registrado';
      }
      return 'Error al registrarse: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }
  
  /**
   * Iniciar sesión
   * @param email Email del usuario
   * @param password Contraseña
   * @return String con error o null si fue exitoso
   */
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Usuario no encontrado';
      } else if (e.code == 'wrong-password') {
        return 'Contraseña incorrecta';
      }
      return 'Error al iniciar sesión: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }
  
  /**
   * Cerrar sesión
   */
  Future<void> logout() async {
    await _auth.signOut();
  }
  
  /**
   * Marcar onboarding como completado
   */
  Future<void> completeOnboarding() async {
    if (_currentUser != null) {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'onboardingCompleted': true,
      });
      _hasCompletedOnboarding = true;
      notifyListeners();
    }
  }
  
  /**
   * Recuperar contraseña
   */
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return 'Error al enviar correo de recuperación';
    }
  }
}