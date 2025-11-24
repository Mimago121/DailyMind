/**
 * Modelo de datos para Hábitos
 * Representa un hábito del usuario con su información y progreso
 */

import 'package:cloud_firestore/cloud_firestore.dart';

/// Frecuencia de un hábito
enum HabitFrequency {
  daily,    // Diario
  weekly,   // Semanal
  monthly   // Mensual
}

/// Categoría de un hábito
enum HabitCategory {
  health,        // Salud
  productivity,  // Productividad
  wellness,      // Bienestar mental
  personal       // Personal
}

class Habit {
  final String id;
  final String name;
  final String description;
  final HabitFrequency frequency;
  final HabitCategory category;
  final List<String> completedDates; // Fechas en formato YYYY-MM-DD
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  
  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.category,
    required this.completedDates,
    required this.currentStreak,
    required this.longestStreak,
    required this.createdAt,
  });
  
  /**
   * Crear un Habit desde un Map (usado al leer de Firestore)
   */
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.toString() == 'HabitFrequency.${map['frequency']}',
        orElse: () => HabitFrequency.daily,
      ),
      category: HabitCategory.values.firstWhere(
        (e) => e.toString() == 'HabitCategory.${map['category']}',
        orElse: () => HabitCategory.personal,
      ),
      completedDates: List<String>.from(map['completedDates'] ?? []),
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  /**
   * Convertir el Habit a Map (usado al guardar en Firestore)
   */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'frequency': frequency.toString().split('.').last,
      'category': category.toString().split('.').last,
      'completedDates': completedDates,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  /**
   * Verificar si el hábito está completado en una fecha específica
   */
  bool isCompletedOnDate(DateTime date) {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return completedDates.contains(dateKey);
  }
  
  /**
   * Obtener el color asociado a la categoría
   */
  static int getCategoryColor(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return 0xFFEF5350; // Rojo
      case HabitCategory.productivity:
        return 0xFF42A5F5; // Azul
      case HabitCategory.wellness:
        return 0xFF66BB6A; // Verde
      case HabitCategory.personal:
        return 0xFFAB47BC; // Morado
    }
  }
  
  /**
   * Obtener el nombre en español de la categoría
   */
  static String getCategoryName(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return 'Salud';
      case HabitCategory.productivity:
        return 'Productividad';
      case HabitCategory.wellness:
        return 'Bienestar';
      case HabitCategory.personal:
        return 'Personal';
    }
  }
  
  /**
   * Obtener el nombre en español de la frecuencia
   */
  static String getFrequencyName(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Diario';
      case HabitFrequency.weekly:
        return 'Semanal';
      case HabitFrequency.monthly:
        return 'Mensual';
    }
  }
}