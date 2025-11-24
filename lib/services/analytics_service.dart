/**
 * Servicio de análisis y estadísticas
 * Analiza datos de hábitos, moods y diario para generar insights
 */

import '../models/habit_model.dart';
import '../models/mood_model.dart';
import '../models/journal_entry_model.dart';

class AnalyticsService {
  
  /**
   * Calcular porcentaje de completitud de hábitos en un periodo
   */
  double calculateHabitCompletionRate(List<Habit> habits, DateTime startDate, DateTime endDate) {
    if (habits.isEmpty) return 0.0;
    
    int totalExpected = 0;
    int totalCompleted = 0;
    
    for (var habit in habits) {
      final days = endDate.difference(startDate).inDays + 1;
      
      if (habit.frequency == HabitFrequency.daily) {
        totalExpected += days;
      } else if (habit.frequency == HabitFrequency.weekly) {
        totalExpected += (days / 7).ceil();
      } else if (habit.frequency == HabitFrequency.monthly) {
        totalExpected += (days / 30).ceil();
      }
      
      // Contar completados en el rango
      for (var dateStr in habit.completedDates) {
        final date = DateTime.parse(dateStr);
        if (date.isAfter(startDate.subtract(const Duration(days: 1))) && 
            date.isBefore(endDate.add(const Duration(days: 1)))) {
          totalCompleted++;
        }
      }
    }
    
    return totalExpected > 0 ? (totalCompleted / totalExpected) * 100 : 0.0;
  }
  
  /**
   * Obtener distribución de moods en un periodo
   */
  Map<MoodType, int> getMoodDistribution(List<MoodEntry> moods) {
    final distribution = <MoodType, int>{
      MoodType.veryHappy: 0,
      MoodType.happy: 0,
      MoodType.neutral: 0,
      MoodType.sad: 0,
      MoodType.verySad: 0,
    };
    
    for (var mood in moods) {
      distribution[mood.moodType] = (distribution[mood.moodType] ?? 0) + 1;
    }
    
    return distribution;
  }
  
  /**
   * Calcular el mood promedio (1-5)
   */
  double calculateAverageMood(List<MoodEntry> moods) {
    if (moods.isEmpty) return 3.0;
    
    final sum = moods.fold<int>(0, (sum, mood) {
      switch (mood.moodType) {
        case MoodType.veryHappy:
          return sum + 5;
        case MoodType.happy:
          return sum + 4;
        case MoodType.neutral:
          return sum + 3;
        case MoodType.sad:
          return sum + 2;
        case MoodType.verySad:
          return sum + 1;
      }
    });
    
    return sum / moods.length;
  }
  
  /**
   * Analizar palabras frecuentes en el diario
   * Retorna un mapa con palabra -> frecuencia
   */
  Map<String, int> analyzeFrequentWords(
    List<JournalEntry> entries,
    {bool happyWords = true}
  ) {
    final wordFrequency = <String, int>{};
    
    // Palabras comunes a ignorar en español
    final stopWords = {
      'el', 'la', 'de', 'que', 'y', 'a', 'en', 'un', 'ser', 'se', 'no', 'haber',
      'por', 'con', 'su', 'para', 'como', 'estar', 'tener', 'le', 'lo', 'todo',
      'pero', 'más', 'hacer', 'o', 'poder', 'decir', 'este', 'ir', 'otro', 'ese',
      'me', 'mi', 'te', 'tu', 'él', 'ella', 'nos', 'les', 'hay', 'del', 'al',
      'una', 'los', 'las', 'unos', 'unas', 'era', 'fue', 'he', 'ha', 'han',
    };
    
    for (var entry in entries) {
      // Seleccionar el texto según si buscamos palabras felices o tristes
      final text = happyWords ? entry.whatMadeHappy : entry.whatMadeSad;
      
      if (text.isEmpty) continue;
      
      // Dividir en palabras y limpiar
      final words = text.toLowerCase()
          .replaceAll(RegExp(r'[^\wáéíóúñ\s]'), '')
          .split(RegExp(r'\s+'));
      
      for (var word in words) {
        // Ignorar palabras muy cortas o stopwords
        if (word.length < 4 || stopWords.contains(word)) continue;
        
        wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
      }
    }
    
    // Ordenar por frecuencia y retornar top 10
    final sortedEntries = wordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(10));
  }
  
  /**
   * Obtener el hábito con mejor racha
   */
  Habit? getBestStreakHabit(List<Habit> habits) {
    if (habits.isEmpty) return null;
    
    return habits.reduce((current, next) {
      return next.longestStreak > current.longestStreak ? next : current;
    });
  }
  
  /**
   * Contar días totales con mood registrado
   */
  int getTotalMoodDays(List<MoodEntry> moods) {
    return moods.length;
  }
  
  /**
   * Obtener racha de días consecutivos con mood registrado
   */
  int getMoodStreak(List<MoodEntry> moods) {
    if (moods.isEmpty) return 0;
    
    final sortedMoods = moods.map((m) => m.date).toList()
      ..sort((a, b) => b.compareTo(a));
    
    int streak = 1;
    DateTime currentDate = DateTime.now();
    
    // Verificar si hay entrada de hoy
    if (!_isSameDay(sortedMoods.first, currentDate)) {
      return 0;
    }
    
    for (int i = 1; i < sortedMoods.length; i++) {
      final expectedDate = currentDate.subtract(Duration(days: i));
      if (_isSameDay(sortedMoods[i], expectedDate)) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  /**
   * Obtener total de entradas en el diario
   */
  int getTotalJournalEntries(List<JournalEntry> entries) {
    return entries.length;
  }
  
  /**
   * Calcular porcentaje de días felices vs tristes
   */
  Map<String, double> getHappinessSadnessRatio(List<MoodEntry> moods) {
    if (moods.isEmpty) {
      return {'happy': 0.0, 'sad': 0.0, 'neutral': 0.0};
    }
    
    int happy = 0;
    int sad = 0;
    int neutral = 0;
    
    for (var mood in moods) {
      switch (mood.moodType) {
        case MoodType.veryHappy:
        case MoodType.happy:
          happy++;
          break;
        case MoodType.sad:
        case MoodType.verySad:
          sad++;
          break;
        case MoodType.neutral:
          neutral++;
          break;
      }
    }
    
    final total = moods.length;
    return {
      'happy': (happy / total) * 100,
      'sad': (sad / total) * 100,
      'neutral': (neutral / total) * 100,
    };
  }
  
  /**
   * Helper: Verificar si dos fechas son el mismo día
   */
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}