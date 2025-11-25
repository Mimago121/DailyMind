/**
 * Modelo de datos para el usuario
 * Representa la información del perfil del usuario
 */

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String? photoURL;
  final bool onboardingCompleted;
  final bool isAdmin;
  final DateTime createdAt;
  final List<String> selectedGoals;      // Objetivos del onboarding
  final List<String> selectedCategories; // Categorías del onboarding
  
  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    this.photoURL,
    required this.onboardingCompleted,
    this.isAdmin = false,
    required this.createdAt,
    this.selectedGoals = const [],
    this.selectedCategories = const [],
  });
  
  /**
   * Crear un UserModel desde un Map (usado al leer de Firestore)
   */
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      photoURL: map['photoURL'],
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      selectedGoals: List<String>.from(map['selectedGoals'] ?? []),
      selectedCategories: List<String>.from(map['selectedCategories'] ?? []),
    );
  }
  
  /**
   * Convertir el UserModel a Map (usado al guardar en Firestore)
   */
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'photoURL': photoURL,
      'onboardingCompleted': onboardingCompleted,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
      'selectedGoals': selectedGoals,
      'selectedCategories': selectedCategories,
    };
  }
  
  /**
   * Copiar con cambios
   */
  UserModel copyWith({
    String? name,
    String? phone,
    String? location,
    String? photoURL,
    bool? onboardingCompleted,
    bool? isAdmin,
    List<String>? selectedGoals,
    List<String>? selectedCategories,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      photoURL: photoURL ?? this.photoURL,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt,
      selectedGoals: selectedGoals ?? this.selectedGoals,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }
}