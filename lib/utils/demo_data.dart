/**
 * Utilidad para generar datos de demostración
 * Llena la app con datos realistas de un mes de uso
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';
import '../models/mood_model.dart';
import '../models/journal_entry_model.dart';
import '../services/firestore_service.dart';

class DemoDataGenerator {
  final FirestoreService _firestoreService = FirestoreService();

  /**
   * Genera todos los datos de demostración
   */
  Future<void> generateDemoData(String userId) async {
    await _generateHabits(userId);
    await _generateMoods(userId);
    await _generateJournalEntries(userId);
  }

  /**
   * Genera hábitos de ejemplo con progreso realista
   */
  Future<void> _generateHabits(String userId) async {
    final now = DateTime.now();
    
    final habits = [
      {
        'name': 'Beber 2L de agua',
        'description': 'Mantenerme hidratado durante el día',
        'frequency': HabitFrequency.daily,
        'category': HabitCategory.health,
        'completionRate': 0.85, // 85% de días completados
      },
      {
        'name': 'Meditar 10 minutos',
        'description': 'Practicar mindfulness cada mañana',
        'frequency': HabitFrequency.daily,
        'category': HabitCategory.wellness,
        'completionRate': 0.70,
      },
      {
        'name': 'Hacer ejercicio',
        'description': '30 minutos de actividad física',
        'frequency': HabitFrequency.daily,
        'category': HabitCategory.health,
        'completionRate': 0.60,
      },
      {
        'name': 'Leer 30 minutos',
        'description': 'Leer antes de dormir',
        'frequency': HabitFrequency.daily,
        'category': HabitCategory.personal,
        'completionRate': 0.75,
      },
      {
        'name': 'Escribir en el diario',
        'description': 'Reflexionar sobre el día',
        'frequency': HabitFrequency.daily,
        'category': HabitCategory.wellness,
        'completionRate': 0.50,
      },
      {
        'name': 'Llamar a familia',
        'description': 'Mantener contacto con seres queridos',
        'frequency': HabitFrequency.weekly,
        'category': HabitCategory.personal,
        'completionRate': 0.90,
      },
      {
        'name': 'Revisar objetivos',
        'description': 'Planificar la semana',
        'frequency': HabitFrequency.weekly,
        'category': HabitCategory.productivity,
        'completionRate': 0.80,
      },
      {
        'name': 'Organizar espacio',
        'description': 'Limpieza profunda del hogar',
        'frequency': HabitFrequency.monthly,
        'category': HabitCategory.personal,
        'completionRate': 1.0,
      },
    ];

    for (int i = 0; i < habits.length; i++) {
      final habitData = habits[i];
      final completedDates = <String>[];
      
      // Generar fechas completadas según la frecuencia
      if (habitData['frequency'] == HabitFrequency.daily) {
        for (int day = 30; day >= 0; day--) {
          final date = now.subtract(Duration(days: day));
          // Usar la tasa de completitud para decidir si se completó
          if (_shouldComplete(habitData['completionRate'] as double)) {
            completedDates.add(_getDateKey(date));
          }
        }
      } else if (habitData['frequency'] == HabitFrequency.weekly) {
        for (int week = 4; week >= 0; week--) {
          final date = now.subtract(Duration(days: week * 7));
          if (_shouldComplete(habitData['completionRate'] as double)) {
            completedDates.add(_getDateKey(date));
          }
        }
      } else if (habitData['frequency'] == HabitFrequency.monthly) {
        completedDates.add(_getDateKey(now.subtract(const Duration(days: 15))));
      }

      final habit = Habit(
        id: 'demo_habit_$i',
        name: habitData['name'] as String,
        description: habitData['description'] as String,
        frequency: habitData['frequency'] as HabitFrequency,
        category: habitData['category'] as HabitCategory,
        completedDates: completedDates,
        currentStreak: _calculateStreak(completedDates),
        longestStreak: _calculateLongestStreak(completedDates),
        createdAt: now.subtract(const Duration(days: 30)),
      );

      await _firestoreService.createHabit(userId, habit);
    }
  }

  /**
   * Genera moods de los últimos 30 días
   */
  Future<void> _generateMoods(String userId) async {
    final now = DateTime.now();
    final moods = [
      MoodType.veryHappy,
      MoodType.happy,
      MoodType.neutral,
      MoodType.sad,
      MoodType.verySad,
    ];

    final notes = [
      'Día increíble, todo salió perfecto',
      'Buen día en general',
      'Día normal, sin novedades',
      'Un poco estresado por el trabajo',
      'Día difícil',
      'Muy productivo hoy',
      'Pasé tiempo con amigos',
      'Completé mis objetivos del día',
      'Necesito descansar más',
      'Gran progreso en mis proyectos',
    ];

    // Generar patrón realista: más días felices que tristes
    final moodPattern = [
      MoodType.happy, MoodType.veryHappy, MoodType.happy, MoodType.neutral,
      MoodType.happy, MoodType.veryHappy, MoodType.happy, MoodType.neutral,
      MoodType.sad, MoodType.neutral, MoodType.happy, MoodType.veryHappy,
      MoodType.happy, MoodType.happy, MoodType.neutral, MoodType.veryHappy,
      MoodType.happy, MoodType.neutral, MoodType.happy, MoodType.veryHappy,
      MoodType.sad, MoodType.neutral, MoodType.happy, MoodType.happy,
      MoodType.veryHappy, MoodType.happy, MoodType.neutral, MoodType.happy,
      MoodType.veryHappy, MoodType.happy,
    ];

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: 30 - i));
      final mood = MoodEntry(
        id: 'demo_mood_$i',
        moodType: moodPattern[i % moodPattern.length],
        date: date,
        note: i % 3 == 0 ? notes[i % notes.length] : null,
      );

      await _firestoreService.saveMood(userId, mood);
    }
  }

  /**
   * Genera entradas de diario realistas
   */
  Future<void> _generateJournalEntries(String userId) async {
    final now = DateTime.now();
    
    final entries = [
      {
        'days_ago': 0,
        'happy': 'Terminé mi proyecto de DailyMind, quedó increíble. Muy orgulloso del resultado.',
        'sad': 'Un poco de presión por la fecha de entrega.',
        'free': 'Ha sido un mes de mucho aprendizaje. Me siento capaz de crear aplicaciones completas ahora.',
      },
      {
        'days_ago': 2,
        'happy': 'Tuve una gran conversación con mi familia. Me apoyaron mucho.',
        'sad': '',
        'free': 'A veces subestimo lo importante que es mantener el contacto con mis seres queridos.',
      },
      {
        'days_ago': 5,
        'happy': 'Logré mantener todos mis hábitos esta semana. Me siento muy disciplinado.',
        'sad': 'El trabajo estuvo estresante, muchas reuniones.',
        'free': 'Necesito encontrar mejor balance entre productividad y descanso.',
      },
      {
        'days_ago': 7,
        'happy': 'Empecé a usar DailyMind y ya veo mejoras en mi organización.',
        'sad': '',
        'free': 'Tracking de hábitos realmente funciona. Estoy más consciente de mis acciones diarias.',
      },
      {
        'days_ago': 10,
        'happy': 'Salí a caminar por el parque. El ejercicio me hace sentir genial.',
        'sad': 'Dormí poco anoche.',
        'free': 'El sueño es fundamental. Debo priorizarlo más.',
      },
      {
        'days_ago': 12,
        'happy': 'Terminé de leer ese libro que tenía pendiente. Muy inspirador.',
        'sad': '',
        'free': 'La lectura me ayuda a desconectar y aprender cosas nuevas.',
      },
      {
        'days_ago': 15,
        'happy': 'Cociné una receta nueva y salió deliciosa.',
        'sad': 'Tuve una discusión con un amigo.',
        'free': 'A veces las relaciones requieren trabajo, pero vale la pena.',
      },
      {
        'days_ago': 18,
        'happy': 'Gran día de productividad. Completé todas mis tareas.',
        'sad': '',
        'free': 'Cuando planifico bien mi día, todo fluye mejor.',
      },
      {
        'days_ago': 20,
        'happy': 'Vi una película increíble con amigos.',
        'sad': 'No hice ejercicio esta semana.',
        'free': 'Necesito ser más consistente con el ejercicio.',
      },
      {
        'days_ago': 23,
        'happy': 'Medité 20 minutos hoy. Me siento muy en paz.',
        'sad': '',
        'free': 'La meditación realmente marca la diferencia en mi estado mental.',
      },
      {
        'days_ago': 25,
        'happy': 'Aprendí algo nuevo en programación.',
        'sad': 'El proyecto del trabajo va lento.',
        'free': 'El aprendizaje continuo es clave para crecer profesionalmente.',
      },
      {
        'days_ago': 28,
        'happy': 'Llamé a mis abuelos. Siempre me alegra hablar con ellos.',
        'sad': '',
        'free': 'La familia es lo más importante.',
      },
    ];

    for (int i = 0; i < entries.length; i++) {
      final entryData = entries[i];
      final date = now.subtract(Duration(days: entryData['days_ago'] as int));
      
      final entry = JournalEntry(
        id: 'demo_journal_$i',
        date: date,
        whatMadeHappy: entryData['happy'] as String,
        whatMadeSad: entryData['sad'] as String,
        freeWriting: entryData['free'] as String,
        createdAt: date,
      );

      await _firestoreService.createJournalEntry(userId, entry);
    }
  }

  // Helpers
  bool _shouldComplete(double rate) {
    return (DateTime.now().millisecondsSinceEpoch % 100) / 100 < rate;
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _calculateStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;
    
    final sorted = completedDates.map((d) => DateTime.parse(d)).toList()
      ..sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    final now = DateTime.now();
    
    for (int i = 0; i <= sorted.length; i++) {
      final expectedDate = now.subtract(Duration(days: i));
      final hasEntry = sorted.any((d) => 
        d.year == expectedDate.year && 
        d.month == expectedDate.month && 
        d.day == expectedDate.day
      );
      
      if (hasEntry) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    
    return streak;
  }

  int _calculateLongestStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;
    
    final sorted = completedDates.map((d) => DateTime.parse(d)).toList()
      ..sort();
    
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }
}