/**
 * Modelo de datos para entradas del diario personal
 * Representa una entrada diaria con reflexiones del usuario
 */

import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final String whatMadeHappy;      // ¿Qué me hizo feliz hoy?
  final String whatMadeSad;        // ¿Qué me hizo triste hoy?
  final String freeWriting;        // Escritura libre
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  JournalEntry({
    required this.id,
    required this.date,
    required this.whatMadeHappy,
    required this.whatMadeSad,
    required this.freeWriting,
    required this.createdAt,
    this.updatedAt,
  });
  
  /**
   * Crear un JournalEntry desde un Map (usado al leer de Firestore)
   */
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      whatMadeHappy: map['whatMadeHappy'] ?? '',
      whatMadeSad: map['whatMadeSad'] ?? '',
      freeWriting: map['freeWriting'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
  
  /**
   * Convertir el JournalEntry a Map (usado al guardar en Firestore)
   */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'whatMadeHappy': whatMadeHappy,
      'whatMadeSad': whatMadeSad,
      'freeWriting': freeWriting,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
  
  /**
   * Verificar si la entrada está vacía
   */
  bool get isEmpty {
    return whatMadeHappy.trim().isEmpty &&
           whatMadeSad.trim().isEmpty &&
           freeWriting.trim().isEmpty;
  }
  
  /**
   * Obtener un resumen corto de la entrada
   */
  String getPreview({int maxLength = 100}) {
    String preview = '';
    
    if (whatMadeHappy.isNotEmpty) {
      preview = whatMadeHappy;
    } else if (freeWriting.isNotEmpty) {
      preview = freeWriting;
    } else if (whatMadeSad.isNotEmpty) {
      preview = whatMadeSad;
    }
    
    if (preview.length > maxLength) {
      return '${preview.substring(0, maxLength)}...';
    }
    
    return preview.isEmpty ? 'Entrada sin texto' : preview;
  }
  
  /**
   * Copiar con cambios (usado para actualizaciones)
   */
  JournalEntry copyWith({
    String? whatMadeHappy,
    String? whatMadeSad,
    String? freeWriting,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id,
      date: date,
      whatMadeHappy: whatMadeHappy ?? this.whatMadeHappy,
      whatMadeSad: whatMadeSad ?? this.whatMadeSad,
      freeWriting: freeWriting ?? this.freeWriting,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}