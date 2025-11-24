/**
 * Pantalla del Calendario de Mood
 * Muestra un calendario mensual con los estados de ánimo registrados
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/mood_model.dart';

class MoodCalendarScreen extends StatefulWidget {
  const MoodCalendarScreen({super.key});

  @override
  State<MoodCalendarScreen> createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends State<MoodCalendarScreen> {
  final _firestoreService = FirestoreService();
  DateTime _selectedMonth = DateTime.now();
  Map<int, MoodEntry> _moodsMap = {};

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Mood'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showMoodLegend,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de mes
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy', 'es_ES').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final now = DateTime.now();
                    final nextMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                    
                    // No permitir ir más allá del mes actual
                    if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                      setState(() {
                        _selectedMonth = nextMonth;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Calendario
          Expanded(
            child: FutureBuilder<List<MoodEntry>>(
              future: _firestoreService.getMoodsForMonth(
                userId,
                _selectedMonth.year,
                _selectedMonth.month,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final moods = snapshot.data ?? [];
                _moodsMap = {
                  for (var mood in moods) mood.date.day: mood
                };

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCalendar(),
                      const SizedBox(height: 24),
                      _buildMonthStats(moods),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMoodDialog(userId),
        icon: const Icon(Icons.add),
        label: const Text('Registrar Mood'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );

    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Domingo

    return Column(
      children: [
        // Cabecera con días de la semana
        Row(
          children: ['D', 'L', 'M', 'X', 'J', 'V', 'S'].map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Días del mes
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: startingWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startingWeekday) {
              return const SizedBox.shrink();
            }

            final day = index - startingWeekday + 1;
            final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
            final mood = _moodsMap[day];
            final isToday = _isToday(date);
            final isFuture = date.isAfter(DateTime.now());

            return GestureDetector(
              onTap: isFuture ? null : () => _showDayMoodDialog(date, mood),
              child: Container(
                decoration: BoxDecoration(
                  color: mood != null
                      ? Color(MoodEntry.getMoodColor(mood.moodType)).withOpacity(0.3)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: Colors.purple, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isFuture ? Colors.grey.shade400 : Colors.black87,
                      ),
                    ),
                    if (mood != null)
                      Text(
                        MoodEntry.getMoodEmoji(mood.moodType),
                        style: const TextStyle(fontSize: 20),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthStats(List<MoodEntry> moods) {
    if (moods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aún no has registrado ningún mood este mes',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final moodCounts = <MoodType, int>{};
    for (var mood in moods) {
      moodCounts[mood.moodType] = (moodCounts[mood.moodType] ?? 0) + 1;
    }

    // Encontrar el mood más frecuente
    var mostFrequentMood = moodCounts.entries.first;
    for (var entry in moodCounts.entries) {
      if (entry.value > mostFrequentMood.value) {
        mostFrequentMood = entry;
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del mes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Has registrado ${moods.length} días este mes',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Tu mood más frecuente: ${MoodEntry.getMoodEmoji(mostFrequentMood.key)} ${MoodEntry.getMoodName(mostFrequentMood.key)} (${mostFrequentMood.value} días)',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Distribución de moods
            ...MoodType.values.map((type) {
              final count = moodCounts[type] ?? 0;
              if (count == 0) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      MoodEntry.getMoodEmoji(type),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MoodEntry.getMoodName(type),
                            style: const TextStyle(fontSize: 14),
                          ),
                          LinearProgressIndicator(
                            value: count / moods.length,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(MoodEntry.getMoodColor(type)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$count días',
                      style: const TextStyle(
                        fontSize: 12,
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
    );
  }

  void _showAddMoodDialog(String userId) {
    MoodType? selectedMood;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('¿Cómo te sientes hoy?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: MoodType.values.map((type) {
                        final isSelected = selectedMood == type;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedMood = type;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(MoodEntry.getMoodColor(type)).withOpacity(0.3)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Color(MoodEntry.getMoodColor(type))
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  MoodEntry.getMoodEmoji(type),
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  MoodEntry.getMoodName(type),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                        border: OutlineInputBorder(),
                        hintText: '¿Qué ha pasado hoy?',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedMood == null
                      ? null
                      : () async {
                          final mood = MoodEntry(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            moodType: selectedMood!,
                            date: DateTime.now(),
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          );

                          await _firestoreService.saveMood(userId, mood);
                          if (context.mounted) {
                            Navigator.pop(context);
                            setState(() {}); // Refrescar calendario
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mood registrado ✅')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDayMoodDialog(DateTime date, MoodEntry? existingMood) {
    final dateStr = DateFormat('d \'de\' MMMM', 'es_ES').format(date);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dateStr),
          content: existingMood != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      MoodEntry.getMoodEmoji(existingMood.moodType),
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      MoodEntry.getMoodName(existingMood.moodType),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (existingMood.note != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          existingMood.note!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                )
              : const Text('No hay mood registrado para este día'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showMoodLegend() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leyenda de Moods'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: MoodType.values.map((type) {
              return ListTile(
                leading: Text(
                  MoodEntry.getMoodEmoji(type),
                  style: const TextStyle(fontSize: 32),
                ),
                title: Text(MoodEntry.getMoodName(type)),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(MoodEntry.getMoodColor(type)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}