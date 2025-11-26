/**
 * Pantalla de Perfil (Final y Corregida)
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
import 'admin_screen.dart';

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
    final userId = user?.uid;

    if (userId == null || userId.trim().isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditingProfile ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() => _isEditingProfile = !_isEditingProfile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(authService),
          ),
        ],
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text('No se pudo cargar el perfil'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? user?.displayName ?? 'Usuario';
          final email = data['email'] ?? user?.email ?? '';
          final phone = data['phone'] ?? '';
          final location = data['location'] ?? '';

          _nameController.text = name;
          _phoneController.text = phone;
          _locationController.text = location;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(name, email),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactInfo(name, email, phone, location, userId),

                      const SizedBox(height: 24),

                      if (!_isEditingProfile && location.isNotEmpty)
                        _buildMapSection(location),

                      const SizedBox(height: 24),

                      _buildAchievements(userId),

                      const SizedBox(height: 24),

                      _buildAdmin(userId),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar Sesión'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _showLogoutDialog(authService),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _generateDemoData(userId),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generar Datos Demo (1 mes)'),
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

  // HEADER
  Widget _buildHeader(String name, String email) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildAvatar(name),
          const SizedBox(height: 16),
          _isEditingProfile
              ? _buildTextField(_nameController)
              : Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _getColorFromString(name),
            _getColorFromString(name).withOpacity(0.7),
          ],
        ),
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(fontSize: 48, color: Colors.white),
        ),
      ),
    );
  }

   Widget _buildTextField(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Escribe aquí...',
        ),
      ),
    );
  }

  // CONTACT INFO
  Widget _buildContactInfo(
    String name,
    String email,
    String phone,
    String location,
    String userId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de Contacto',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  label: "Email",
                  value: email,
                  isEditing: false,
                ),
                const Divider(height: 24),
                _isEditingProfile
                    ? _EditableContactRow(
                        icon: Icons.phone,
                        label: "Teléfono",
                        controller: _phoneController,
                      )
                    : _ContactRow(
                        icon: Icons.phone,
                        label: "Teléfono",
                        value: phone,
                        isEditing: false,
                      ),
                const Divider(height: 24),
                _isEditingProfile
                    ? _EditableContactRow(
                        icon: Icons.location_on,
                        label: "Ubicación",
                        controller: _locationController,
                      )
                    : _ContactRow(
                        icon: Icons.location_on,
                        label: "Ubicación",
                        value: location,
                        isEditing: false,
                      ),
              ],
            ),
          ),
        ),
        if (_isEditingProfile)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _saveProfile(userId),
                child: const Text("Guardar Cambios"),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _saveProfile(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'location': _locationController.text.trim(),
    });

    if (!mounted) return;

    setState(() => _isEditingProfile = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }

  // MAP
  Widget _buildMapSection(String location) {
    final coords = _getCoordinatesFromLocation(location);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación en el Mapa',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(coords['lat']!, coords['lng']!),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(coords['lat']!, coords['lng']!),
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, double> _getCoordinatesFromLocation(String location) {
    final loc = location.toLowerCase();

    const cities = {
      'madrid': {'lat': 40.4168, 'lng': -3.7038},
      'barcelona': {'lat': 41.3851, 'lng': 2.1734},
      'valencia': {'lat': 39.4699, 'lng': -0.3763},
      'sevilla': {'lat': 37.3891, 'lng': -5.9845},
    };

    return cities[loc] ?? {'lat': 40.4168, 'lng': -3.7038};
  }

  Color _getColorFromString(String str) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = str.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.teal,
      Colors.red,
    ];

    return colors[hash.abs() % colors.length];
  }

  // ACHIEVEMENTS
  Widget _buildAchievements(String userId) {
    return StreamBuilder<List<Habit>>(
      stream: _firestoreService.getHabits(userId),
      builder: (context, habitSnap) {
        return StreamBuilder<List<MoodEntry>>(
          stream: _firestoreService.getAllMoods(userId),
          builder: (context, moodSnap) {
            final habits = habitSnap.data ?? [];
            final moods = moodSnap.data ?? [];

            final bestHabit = _analyticsService.getBestStreakHabit(habits);
            final moodStreak = _analyticsService.getMoodStreak(moods);
            final totalMoodDays = _analyticsService.getTotalMoodDays(moods);

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _AchievementCard(
                        icon: Icons.local_fire_department,
                        title: "Mejor Racha",
                        value: bestHabit != null
                            ? "${bestHabit.longestStreak} días"
                            : "0 días",
                        subtitle: bestHabit?.name ?? "Sin hábitos",
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AchievementCard(
                        icon: Icons.calendar_today,
                        title: "Racha Mood",
                        value: "$moodStreak días",
                        subtitle: "consecutivos",
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
                        title: "Hábitos",
                        value: "${habits.length}",
                        subtitle: "activos",
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AchievementCard(
                        icon: Icons.mood,
                        title: "Días Registrados",
                        value: "$totalMoodDays",
                        subtitle: "moods",
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
    );
  }

  // ADMIN
  Widget _buildAdmin(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final isAdmin = data?['isAdmin'] ?? false;

        if (!isAdmin) return const SizedBox.shrink();

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text("Panel de Administración"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            },
          ),
        );
      },
    );
  }

  // LOGOUT
  void _showLogoutDialog(AuthService auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Cerrar Sesión?"),
        content: const Text("¿Seguro que quieres cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
            },
            child: const Text("Cerrar Sesión"),
          ),
        ],
      ),
    );
  }

  // DEMO DATA
  Future<void> _generateDemoData(String userId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Generar datos de demostración"),
        content: const Text(
          "Esto generará hábitos, moods y diario para 1 mes.\n"
          "¿Quieres continuar?",
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Generar"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (ok != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final generator = DemoDataGenerator();

    try {
      await generator.generateDemoData(userId);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Datos de demostración generados"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ------------------------------------------------------
// WIDGETS
// ------------------------------------------------------

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
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                value.isEmpty ? "No especificado" : value,
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
