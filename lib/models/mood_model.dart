/**
 * Modelo de datos para el estado de ánimo (Mood)
 * Representa el mood registrado por el usuario en un día específico
 */

import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de mood disponibles
enum MoodType {
  veryHappy,  // Muy feliz
  happy,      // Feliz
  neutral,    // Neutral
  sad,        // Triste
  verySad     // Muy triste
}

class MoodEntry {
  final String id;
  final MoodType moodType;
  final DateTime date;
  final String? note; // Nota opcional del usuario
  
  MoodEntry({
    required this.id,
    required this.moodType,
    required this.date,
    this.note,
  });
  
  /**
   * Crear un MoodEntry desde un Map (usado al leer de Firestore)
   */
  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'] ?? '',
      moodType: MoodType.values.firstWhere(
        (e) => e.toString() == 'MoodType.${map['moodType']}',
        orElse: () => MoodType.neutral,
      ),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'],
    );
  }
  
  /**
   * Convertir el MoodEntry a Map (usado al guardar en Firestore)
   */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'moodType': moodType.toString().split('.').last,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }
  
  /**
   * Obtener el emoji correspondiente al mood
   */
  static String getMoodEmoji(MoodType mood) {
    switch (mood) {
      case MoodType.veryHappy:
        return '😄';
      case MoodType.happy:
        return '🙂';
      case MoodType.neutral:
        return '😐';
      case MoodType.sad:
        return '😔';
      case MoodType.verySad:
        return '😢';
    }
  }
  
  /**
   * Obtener el color correspondiente al mood
   */
  static int getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.veryHappy:
        return 0xFF4CAF50; // Verde brillante
      case MoodType.happy:
        return 0xFF8BC34A; // Verde claro
      case MoodType.neutral:
        return 0xFFFFC107; // Amarillo
      case MoodType.sad:
        return 0xFFFF9800; // Naranja
      case MoodType.verySad:
        return 0xFFF44336; // Rojo
    }
  }
  
  /**
   * Obtener el nombre en español del mood
   */
  static String getMoodName(MoodType mood) {
    switch (mood) {
      case MoodType.veryHappy:
        return 'Muy feliz';
      case MoodType.happy:
        return 'Feliz';
      case MoodType.neutral:
        return 'Neutral';
      case MoodType.sad:
        return 'Triste';
      case MoodType.verySad:
        return 'Muy triste';
    }
  }
  
  /**
   * Obtener el valor numérico del mood (1-5)
   */
  static int getMoodValue(MoodType mood) {
    switch (mood) {
      case MoodType.veryHappy:
        return 5;
      case MoodType.happy:
        return 4;
      case MoodType.neutral:
        return 3;
      case MoodType.sad:
        return 2;
      case MoodType.verySad:
        return 1;
    }
  }
}