/**
 * Pantalla de Administración
 * Solo accesible para usuarios con isAdmin = true
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.red.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data?.docs ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final userId = userDoc.id;
              final name = userData['name'] ?? 'Sin nombre';
              final email = userData['email'] ?? 'Sin email';
              final isAdmin = userData['isAdmin'] ?? false;
              final createdAt = (userData['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Colors.red : Colors.purple,
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(name)),
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(email),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: email,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.phone,
                            label: 'Teléfono',
                            value: userData['phone'] ?? 'No especificado',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.location_on,
                            label: 'Ubicación',
                            value: userData['location'] ?? 'No especificado',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Registrado',
                            value: createdAt != null
                                ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                                : 'Desconocido',
                          ),
                          const SizedBox(height: 16),

                          // Estadísticas del usuario
                          FutureBuilder<Map<String, int>>(
                            future: _getUserStats(userId),
                            builder: (context, statsSnapshot) {
                              if (!statsSnapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final stats = statsSnapshot.data!;
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _StatChip(
                                    icon: Icons.check_circle,
                                    label: 'Hábitos',
                                    value: '${stats['habits']}',
                                    color: Colors.purple,
                                  ),
                                  _StatChip(
                                    icon: Icons.mood,
                                    label: 'Moods',
                                    value: '${stats['moods']}',
                                    color: Colors.orange,
                                  ),
                                  _StatChip(
                                    icon: Icons.book,
                                    label: 'Diario',
                                    value: '${stats['journal']}',
                                    color: Colors.blue,
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Acciones
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _toggleAdmin(userId, isAdmin),
                                  icon: Icon(
                                    isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                                  ),
                                  label: Text(
                                    isAdmin ? 'Quitar Admin' : 'Hacer Admin',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isAdmin
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _deleteUser(userId, name),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Eliminar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _getUserStats(String userId) async {
    final habits = await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .get();

    final moods = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .get();

    final journal = await _firestore
        .collection('users')
        .doc(userId)
        .collection('journal')
        .get();

    return {
      'habits': habits.docs.length,
      'moods': moods.docs.length,
      'journal': journal.docs.length,
    };
  }

  Future<void> _toggleAdmin(String userId, bool currentIsAdmin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          currentIsAdmin ? '¿Quitar permisos de admin?' : '¿Hacer administrador?',
        ),
        content: Text(
          currentIsAdmin
              ? 'Este usuario perderá acceso al panel de administración.'
              : 'Este usuario tendrá acceso al panel de administración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentIsAdmin ? Colors.orange : Colors.red,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': !currentIsAdmin,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentIsAdmin
                  ? 'Permisos de admin removidos'
                  : 'Usuario promovido a admin',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminarte a ti mismo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar usuario?'),
        content: Text(
          '¿Estás seguro de eliminar a "$userName"?\n\n'
          'Esto eliminará:\n'
          '• Su cuenta\n'
          '• Todos sus hábitos\n'
          '• Todos sus moods\n'
          '• Todas sus entradas de diario\n\n'
          '⚠️ Esta acción no se puede deshacer.',
        ),
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
      try {
        // Eliminar subcolecciones
        final batch = _firestore.batch();

        final habits = await _firestore
            .collection('users')
            .doc(userId)
            .collection('habits')
            .get();
        for (var doc in habits.docs) {
          batch.delete(doc.reference);
        }

        final moods = await _firestore
            .collection('users')
            .doc(userId)
            .collection('moods')
            .get();
        for (var doc in moods.docs) {
          batch.delete(doc.reference);
        }

        final journal = await _firestore
            .collection('users')
            .doc(userId)
            .collection('journal')
            .get();
        for (var doc in journal.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        // Eliminar documento del usuario
        await _firestore.collection('users').doc(userId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}