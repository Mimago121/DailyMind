/**
 * Pantalla de Perfil
 * Muestra información del usuario, rachas destacadas y opciones
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../models/habit_model.dart';
import '../models/mood_model.dart';
import '../utils/demo_data.dart';
import '../screens/admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestoreService = FirestoreService();
  final _analyticsService = AnalyticsService();
  bool _isEditingProfile = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final userId = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditingProfile ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditingProfile = !_isEditingProfile;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(authService),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se pudo cargar el perfil'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final name = userData['name'] ?? user?.displayName ?? 'Usuario';
          final email = userData['email'] ?? user?.email ?? '';
          final phone = userData['phone'] ?? '';
          final location = userData['location'] ?? '';

          // Inicializar controladores
          _nameController.text = name;
          _phoneController.text = phone;
          _locationController.text = location;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header con información básica
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isEditingProfile) ...[
                        // Modo edición
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Nombre',
                            ),
                          ),
                        ),
                      ] else ...[
                        // Modo visualización
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información de contacto
                      const Text(
                        'Información de Contacto',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _ContactRow(
                                icon: Icons.email,
                                label: 'Email',
                                value: email,
                                isEditing: false,
                              ),
                              const Divider(height: 24),
                              _isEditingProfile
                                  ? _EditableContactRow(
                                      icon: Icons.phone,
                                      label: 'Teléfono',
                                      controller: _phoneController,
                                    )
                                  : _ContactRow(
                                      icon: Icons.phone,
                                      label: 'Teléfono',
                                      value: phone,
                                      isEditing: false,
                                    ),
                              const Divider(height: 24),
                              _isEditingProfile
                                  ? _EditableContactRow(
                                      icon: Icons.location_on,
                                      label: 'Ubicación',
                                      controller: _locationController,
                                    )
                                  : _ContactRow(
                                      icon: Icons.location_on,
                                      label: 'Ubicación',
                                      value: location,
                                      isEditing: false,
                                    ),
                            ],
                          ),
                        ),
                      ),

                      if (_isEditingProfile) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _saveProfile(userId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Guardar Cambios'),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Mapa de ubicación
                      if (!_isEditingProfile && location.isNotEmpty) ...[
                        const Text(
                          'Ubicación en el Mapa',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                            height: 200,
                            child: _buildMap(location),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Estadísticas y rachas
                      const Text(
                        'Tus Logros',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<List<Habit>>(
                        stream: _firestoreService.getHabits(userId),
                        builder: (habitContext, habitSnapshot) {
                          return StreamBuilder<List<MoodEntry>>(
                            stream: _firestoreService.getAllMoods(userId),
                            builder: (moodContext, moodSnapshot) {
                              final habits = habitSnapshot.data ?? [];
                              final moods = moodSnapshot.data ?? [];

                              final bestHabit = _analyticsService
                                  .getBestStreakHabit(habits);
                              final moodStreak = _analyticsService
                                  .getMoodStreak(moods);
                              final totalMoodDays = _analyticsService
                                  .getTotalMoodDays(moods);

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _AchievementCard(
                                          icon: Icons.local_fire_department,
                                          title: 'Mejor Racha',
                                          value: bestHabit != null
                                              ? '${bestHabit.longestStreak} días'
                                              : '0 días',
                                          subtitle:
                                              bestHabit?.name ?? 'Sin hábitos',
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AchievementCard(
                                          icon: Icons.calendar_today,
                                          title: 'Racha Mood',
                                          value: '$moodStreak días',
                                          subtitle: 'consecutivos',
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _AchievementCard(
                                          icon: Icons.check_circle,
                                          title: 'Hábitos',
                                          value: '${habits.length}',
                                          subtitle: 'activos',
                                          color: Colors.purple,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AchievementCard(
                                          icon: Icons.mood,
                                          title: 'Días Registrados',
                                          value: '$totalMoodDays',
                                          subtitle: 'moods',
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Botón de admin (solo visible para administradores)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, adminSnapshot) {
                          if (adminSnapshot.hasData) {
                            final isAdmin =
                                (adminSnapshot.data!.data()
                                    as Map<String, dynamic>?)?['isAdmin'] ??
                                false;

                            if (isAdmin) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const AdminScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.admin_panel_settings,
                                      ),
                                      label: const Text(
                                        'Panel de Administración',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Botón de cerrar sesión
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(authService),
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar Sesión'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botón de datos de demostración
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _generateDemoData(userId),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generar Datos de Demo (1 mes)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap(String location) {
    final coordinates = _getCoordinatesFromLocation(location);

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(coordinates['lat']!, coordinates['lng']!),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.dailymind',
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(coordinates['lat']!, coordinates['lng']!),
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, double> _getCoordinatesFromLocation(String location) {
    final locations = {
      'madrid': {'lat': 40.4168, 'lng': -3.7038},
      'barcelona': {'lat': 41.3851, 'lng': 2.1734},
      'valencia': {'lat': 39.4699, 'lng': -0.3763},
      'sevilla': {'lat': 37.3891, 'lng': -5.9845},
      'bilbao': {'lat': 43.2630, 'lng': -2.9350},
    };

    final locationLower = location.toLowerCase();
    for (var city in locations.keys) {
      if (locationLower.contains(city)) {
        return locations[city]!;
      }
    }

    return {'lat': 40.4168, 'lng': -3.7038};
  }

  Future<void> _saveProfile(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
      });

      setState(() {
        _isEditingProfile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar perfil: $e')),
        );
      }
    }
  }

  Future<void> _generateDemoData(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Generar datos de demostración?'),
        content: const Text(
          'Esto creará:\n'
          '• 8 hábitos con progreso de 30 días\n'
          '• 30 días de registros de mood\n'
          '• 12 entradas de diario\n\n'
          '⚠️ Esto es solo para demostración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando datos de demostración...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final demoGenerator = DemoDataGenerator();
        await demoGenerator.generateDemoData(userId);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Datos de demostración generados exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showLogoutDialog(AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar Sesión?'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar el diálogo primero
              await authService.logout();
              // El AuthWrapper en main.dart se encargará de mostrar el LoginScreen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

/**
 * Widget de fila de contacto
 */
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'No especificado' : value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/**
 * Widget de fila de contacto editable
 */
class _EditableContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;

  const _EditableContactRow({
    required this.icon,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

/**
 * Tarjeta de logro
 */
class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
