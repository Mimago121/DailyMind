/**
 * Servicio de Firestore
 * Gestiona todas las operaciones con la base de datos
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';
import '../models/mood_model.dart';
import '../models/journal_entry_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ============ HÁBITOS ============

  /**
   * Crear un nuevo hábito
   */
  Future<void> createHabit(String userId, Habit habit) async {
    if (userId.isEmpty) return; // <- evitar crash
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(habit.id)
        .set(habit.toMap());
  }

  /**
   * Obtener todos los hábitos del usuario
   */
  Stream<List<Habit>> getHabits(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty(); // <- evitar crash
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Habit.fromMap(doc.data())).toList();
    });
  }

  /**
   * Actualizar un hábito
   */
  Future<void> updateHabit(String userId, Habit habit) async {
    if (userId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(habit.id)
        .update(habit.toMap());
  }

  /**
   * Eliminar un hábito
   */
  Future<void> deleteHabit(String userId, String habitId) async {
    if (userId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(habitId)
        .delete();
  }

  /**
   * Marcar hábito como completado/no completado en una fecha específica
   */
  Future<void> toggleHabitCompletion(
    String userId,
    String habitId,
    DateTime date,
  ) async {
    if (userId.isEmpty) return;

    final habitRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(habitId);

    final habitDoc = await habitRef.get();
    if (!habitDoc.exists) return;

    final habit = Habit.fromMap(habitDoc.data()!);
    final dateKey = _getDateKey(date);

    final updatedCompletedDates = List<String>.from(habit.completedDates);

    if (updatedCompletedDates.contains(dateKey)) {
      updatedCompletedDates.remove(dateKey);
    } else {
      updatedCompletedDates.add(dateKey);
    }

    final newCurrentStreak = _calculateStreak(updatedCompletedDates);
    final newLongestStreak =
        newCurrentStreak > habit.longestStreak ? newCurrentStreak : habit.longestStreak;

    final updatedHabit = Habit(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      frequency: habit.frequency,
      category: habit.category,
      completedDates: updatedCompletedDates,
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      createdAt: habit.createdAt,
    );

    await habitRef.update(updatedHabit.toMap());
  }

  int _calculateStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;

    final sortedDates = completedDates.map((d) => DateTime.parse(d)).toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime currentDate = DateTime.now();

    for (var date in sortedDates) {
      if (_isSameDay(date, currentDate) ||
          _isSameDay(date, currentDate.subtract(Duration(days: streak)))) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // ============ MOOD (Estado de ánimo) ============

  Future<void> saveMood(String userId, MoodEntry mood) async {
    if (userId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .doc(mood.id)
        .set(mood.toMap());
  }

  Future<List<MoodEntry>> getMoodsForMonth(
    String userId,
    int year,
    int month,
  ) async {
    if (userId.isEmpty) return [];

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs.map((doc) => MoodEntry.fromMap(doc.data())).toList();
  }

  Stream<List<MoodEntry>> getAllMoods(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MoodEntry.fromMap(doc.data())).toList();
    });
  }

  // ============ JOURNAL (Diario) ============

  Future<void> createJournalEntry(String userId, JournalEntry entry) async {
    if (userId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('journal')
        .doc(entry.id)
        .set(entry.toMap());
  }

  Stream<List<JournalEntry>> getJournalEntries(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('journal')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => JournalEntry.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateJournalEntry(String userId, JournalEntry entry) async {
    if (userId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('journal')
        .doc(entry.id)
        .update(entry.toMap());
  }

  Future<void> deleteJournalEntry(String userId, String entryId) async {
    if (userId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('journal')
        .doc(entryId)
        .delete();
  }

  // ============ HELPERS ============

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
