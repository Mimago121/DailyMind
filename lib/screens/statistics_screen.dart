/**
 * Pantalla de Estadísticas
 * Muestra análisis y gráficas del progreso del usuario
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../models/habit_model.dart';
import '../models/mood_model.dart';
import '../models/journal_entry_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _firestoreService = FirestoreService();
  final _analyticsService = AnalyticsService();
  String _selectedPeriod = '30days'; // 7days, 30days, all

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '7days',
                child: Text('Últimos 7 días'),
              ),
              const PopupMenuItem(
                value: '30days',
                child: Text('Últimos 30 días'),
              ),
              const PopupMenuItem(
                value: 'all',
                child: Text('Todo el tiempo'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Habit>>(
        stream: _firestoreService.getHabits(userId),
        builder: (habitContext, habitSnapshot) {
          return StreamBuilder<List<MoodEntry>>(
            stream: _firestoreService.getAllMoods(userId),
            builder: (moodContext, moodSnapshot) {
              return StreamBuilder<List<JournalEntry>>(
                stream: _firestoreService.getJournalEntries(userId),
                builder: (journalContext, journalSnapshot) {
                  if (habitSnapshot.connectionState == ConnectionState.waiting ||
                      moodSnapshot.connectionState == ConnectionState.waiting ||
                      journalSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final habits = habitSnapshot.data ?? [];
                  final moods = _filterByPeriod(moodSnapshot.data ?? []);
                  final journalEntries = _filterJournalByPeriod(journalSnapshot.data ?? []);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resumen general
                        _buildOverviewCards(habits, moods, journalEntries),
                        const SizedBox(height: 24),

                        // Hábitos
                        if (habits.isNotEmpty) ...[
                          _buildSectionTitle('📊 Hábitos'),
                          const SizedBox(height: 12),
                          _buildHabitStats(habits),
                          const SizedBox(height: 24),
                        ],

                        // Mood
                        if (moods.isNotEmpty) ...[
                          _buildSectionTitle('😊 Estado de Ánimo'),
                          const SizedBox(height: 12),
                          _buildMoodStats(moods),
                          const SizedBox(height: 24),
                        ],

                        // Diario - Análisis de palabras
                        if (journalEntries.isNotEmpty) ...[
                          _buildSectionTitle('✍️ Análisis del Diario'),
                          const SizedBox(height: 12),
                          _buildJournalAnalysis(journalEntries),
                          const SizedBox(height: 24),
                        ],

                        // Mejor racha
                        if (habits.isNotEmpty) ...[
                          _buildBestStreak(habits),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<MoodEntry> _filterByPeriod(List<MoodEntry> moods) {
    if (_selectedPeriod == 'all') return moods;

    final now = DateTime.now();
    final days = _selectedPeriod == '7days' ? 7 : 30;
    final cutoffDate = now.subtract(Duration(days: days));

    return moods.where((m) => m.date.isAfter(cutoffDate)).toList();
  }

  List<JournalEntry> _filterJournalByPeriod(List<JournalEntry> entries) {
    if (_selectedPeriod == 'all') return entries;

    final now = DateTime.now();
    final days = _selectedPeriod == '7days' ? 7 : 30;
    final cutoffDate = now.subtract(Duration(days: days));

    return entries.where((e) => e.date.isAfter(cutoffDate)).toList();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOverviewCards(
    List<Habit> habits,
    List<MoodEntry> moods,
    List<JournalEntry> journalEntries,
  ) {
    final moodStreak = _analyticsService.getMoodStreak(moods);
    final bestHabit = _analyticsService.getBestStreakHabit(habits);

    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            title: 'Hábitos',
            value: '${habits.length}',
            subtitle: 'activos',
            icon: Icons.check_circle,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            title: 'Racha Mood',
            value: '$moodStreak',
            subtitle: 'días',
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OverviewCard(
            title: 'Entradas',
            value: '${journalEntries.length}',
            subtitle: 'diario',
            icon: Icons.book,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitStats(List<Habit> habits) {
    final completionRate = _analyticsService.calculateHabitCompletionRate(
      habits,
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    // Agrupar por categoría
    final categoryCount = <HabitCategory, int>{};
    for (var habit in habits) {
      categoryCount[habit.category] = (categoryCount[habit.category] ?? 0) + 1;
    }

    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tasa de Completitud',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: completionRate / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${completionRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hábitos por Categoría',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...HabitCategory.values.map((category) {
                  final count = categoryCount[category] ?? 0;
                  if (count == 0) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(Habit.getCategoryColor(category)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            Habit.getCategoryName(category),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodStats(List<MoodEntry> moods) {
    final distribution = _analyticsService.getMoodDistribution(moods);
    final averageMood = _analyticsService.calculateAverageMood(moods);
    final happinessSadnessRatio = _analyticsService.getHappinessSadnessRatio(moods);

    return Column(
      children: [
        // Promedio
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mood Promedio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getMoodEmojiForAverage(averageMood),
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          averageMood.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'de 5.0',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Distribución
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribución de Moods',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: distribution.entries.map((entry) {
                        final percentage = (entry.value / moods.length) * 100;
                        return PieChartSectionData(
                          color: Color(MoodEntry.getMoodColor(entry.key)),
                          value: entry.value.toDouble(),
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...MoodType.values.map((type) {
                  final count = distribution[type] ?? 0;
                  if (count == 0) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          MoodEntry.getMoodEmoji(type),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            MoodEntry.getMoodName(type),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '$count días',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Ratio Felicidad/Tristeza
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Balance Emocional',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEmotionalBar(
                  'Feliz',
                  happinessSadnessRatio['happy']!,
                  Colors.green,
                  '😊',
                ),
                const SizedBox(height: 12),
                _buildEmotionalBar(
                  'Neutral',
                  happinessSadnessRatio['neutral']!,
                  Colors.amber,
                  '😐',
                ),
                const SizedBox(height: 12),
                _buildEmotionalBar(
                  'Triste',
                  happinessSadnessRatio['sad']!,
                  Colors.orange,
                  '😔',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionalBar(String label, double percentage, Color color, String emoji) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
            const Spacer(),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildJournalAnalysis(List<JournalEntry> entries) {
    final happyWords = _analyticsService.analyzeFrequentWords(entries, happyWords: true);
    final sadWords = _analyticsService.analyzeFrequentWords(entries, happyWords: false);

    return Column(
      children: [
        if (happyWords.isNotEmpty)
          Card(
            elevation: 2,
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('😊', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        'Palabras más frecuentes (Felicidad)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: happyWords.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${entry.key} (${entry.value})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        if (happyWords.isNotEmpty && sadWords.isNotEmpty)
          const SizedBox(height: 12),
        if (sadWords.isNotEmpty)
          Card(
            elevation: 2,
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('😔', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        'Palabras más frecuentes (Tristeza)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sadWords.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${entry.key} (${entry.value})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        if (happyWords.isEmpty && sadWords.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Escribe más en tu diario para ver análisis de palabras',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBestStreak(List<Habit> habits) {
    final bestHabit = _analyticsService.getBestStreakHabit(habits);
    if (bestHabit == null || bestHabit.longestStreak == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 40,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 Mejor Racha',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bestHabit.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${bestHabit.longestStreak} días consecutivos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmojiForAverage(double average) {
    if (average >= 4.5) return '😄';
    if (average >= 3.5) return '🙂';
    if (average >= 2.5) return '😐';
    if (average >= 1.5) return '😔';
    return '😢';
  }
}

/**
 * Tarjeta de resumen general
 */
class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}