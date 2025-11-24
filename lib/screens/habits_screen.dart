/**
 * Pantalla de Hábitos
 * Muestra y gestiona todos los hábitos del usuario
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/habit_model.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = FirestoreService();
  String _sortBy = 'createdAt'; // createdAt, streak, name
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ordenar por',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de creación'),
                trailing: _sortBy == 'createdAt' ? const Icon(Icons.check, color: Colors.purple) : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'createdAt';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: const Text('Racha actual'),
                trailing: _sortBy == 'streak' ? const Icon(Icons.check, color: Colors.purple) : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'streak';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Nombre'),
                trailing: _sortBy == 'name' ? const Icon(Icons.check, color: Colors.purple) : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'name';
                  });
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Orden ascendente'),
                value: _sortAscending,
                onChanged: (value) {
                  setState(() {
                    _sortAscending = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<Habit> _sortHabits(List<Habit> habits) {
    final sorted = List<Habit>.from(habits);
    
    sorted.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'streak':
          comparison = a.currentStreak.compareTo(b.currentStreak);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        default: // createdAt
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hábitos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showSortMenu,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Diarios'),
            Tab(text: 'Semanales'),
            Tab(text: 'Mensuales'),
          ],
        ),
      ),
      body: StreamBuilder<List<Habit>>(
        stream: _firestoreService.getHabits(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final allHabits = snapshot.data ?? [];
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildHabitsList(
                _sortHabits(allHabits.where((h) => h.frequency == HabitFrequency.daily).toList()),
                userId,
                HabitFrequency.daily,
              ),
              _buildHabitsList(
                _sortHabits(allHabits.where((h) => h.frequency == HabitFrequency.weekly).toList()),
                userId,
                HabitFrequency.weekly,
              ),
              _buildHabitsList(
                _sortHabits(allHabits.where((h) => h.frequency == HabitFrequency.monthly).toList()),
                userId,
                HabitFrequency.monthly,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitDialog(userId),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Hábito'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHabitsList(List<Habit> habits, String userId, HabitFrequency frequency) {
    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes hábitos ${Habit.getFrequencyName(frequency).toLowerCase()}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddHabitDialog(userId, preselectedFrequency: frequency),
              icon: const Icon(Icons.add),
              label: const Text('Crear uno ahora'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return _HabitCard(
          habit: habit,
          userId: userId,
          onTap: () => _showHabitDetails(habit, userId),
          onToggle: () async {
            await _firestoreService.toggleHabitCompletion(
              userId,
              habit.id,
              DateTime.now(),
            );
          },
          onDelete: () => _deleteHabit(habit, userId),
        );
      },
    );
  }

  void _showAddHabitDialog(String userId, {HabitFrequency? preselectedFrequency}) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    HabitFrequency selectedFrequency = preselectedFrequency ?? HabitFrequency.daily;
    HabitCategory selectedCategory = HabitCategory.personal;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo Hábito'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del hábito',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HabitFrequency>(
                      value: selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frecuencia',
                        border: OutlineInputBorder(),
                      ),
                      items: HabitFrequency.values.map((freq) {
                        return DropdownMenuItem(
                          value: freq,
                          child: Text(Habit.getFrequencyName(freq)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedFrequency = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HabitCategory>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: HabitCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Color(Habit.getCategoryColor(cat)),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(Habit.getCategoryName(cat)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
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
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa un nombre')),
                      );
                      return;
                    }

                    final habit = Habit(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      frequency: selectedFrequency,
                      category: selectedCategory,
                      completedDates: [],
                      currentStreak: 0,
                      longestStreak: 0,
                      createdAt: DateTime.now(),
                    );

                    await _firestoreService.createHabit(userId, habit);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hábito creado exitosamente')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHabitDetails(Habit habit, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(Habit.getCategoryColor(habit.category)).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Color(Habit.getCategoryColor(habit.category)),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${Habit.getCategoryName(habit.category)} • ${Habit.getFrequencyName(habit.frequency)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (habit.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      habit.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  // Estadísticas
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Racha Actual',
                          value: '${habit.currentStreak}',
                          subtitle: 'días',
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Mejor Racha',
                          value: '${habit.longestStreak}',
                          subtitle: 'días',
                          icon: Icons.emoji_events,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _StatCard(
                    title: 'Total Completado',
                    value: '${habit.completedDates.length}',
                    subtitle: 'veces',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteHabit(habit, userId);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Cerrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteHabit(Habit habit, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar hábito?'),
        content: Text('¿Estás seguro de que quieres eliminar "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteHabit(userId, habit.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hábito eliminado')),
        );
      }
    }
  }
}

/**
 * Tarjeta de hábito individual
 */
class _HabitCard extends StatelessWidget {
  final Habit habit;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.userId,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isCompletedToday = habit.isCompletedOnDate(today);
    final categoryColor = Color(Habit.getCategoryColor(habit.category));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompletedToday ? categoryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox animado
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompletedToday ? categoryColor : Colors.transparent,
                    border: Border.all(
                      color: categoryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isCompletedToday
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              ),
              
              const SizedBox(width: 16),

              // Información del hábito
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            Habit.getCategoryName(habit.category),
                            style: TextStyle(
                              fontSize: 12,
                              color: categoryColor,
                            ),
                          ),
                        ),
                        if (habit.currentStreak > 0) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                          Text(
                            ' ${habit.currentStreak}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de detalles
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/**
 * Tarjeta de estadística
 */
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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
    );
  }
}