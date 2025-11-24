/**
 * Pantalla de Diario Personal
 * Permite crear y ver entradas del diario
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/journal_entry_model.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Diario'),
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: _firestoreService.getJournalEntries(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes entradas en tu diario',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEntryDialog(userId),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primera entrada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _JournalEntryCard(
                entry: entry,
                onTap: () => _showEntryDetails(entry, userId),
                onDelete: () => _deleteEntry(entry, userId),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(userId),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Entrada'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddEntryDialog(String userId, {JournalEntry? existingEntry}) {
    final happyController = TextEditingController(
      text: existingEntry?.whatMadeHappy ?? '',
    );
    final sadController = TextEditingController(
      text: existingEntry?.whatMadeSad ?? '',
    );
    final freeController = TextEditingController(
      text: existingEntry?.freeWriting ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note, color: Colors.purple, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            existingEntry == null
                                ? 'Nueva Entrada de Diario'
                                : 'Editar Entrada',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ¿Qué me hizo feliz?
                    const Row(
                      children: [
                        Text('😊', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text(
                          '¿Qué me hizo feliz hoy?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: happyController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe sobre momentos felices del día...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // ¿Qué me hizo triste?
                    const Row(
                      children: [
                        Text('😔', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text(
                          '¿Qué me hizo sentir triste?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sadController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe sobre momentos difíciles...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Escritura libre
                    const Row(
                      children: [
                        Text('✍️', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text(
                          'Escritura libre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: freeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe lo que quieras...',
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final entry = JournalEntry(
                              id: existingEntry?.id ??
                                  DateTime.now().millisecondsSinceEpoch.toString(),
                              date: existingEntry?.date ?? DateTime.now(),
                              whatMadeHappy: happyController.text.trim(),
                              whatMadeSad: sadController.text.trim(),
                              freeWriting: freeController.text.trim(),
                              createdAt: existingEntry?.createdAt ?? DateTime.now(),
                              updatedAt: existingEntry != null ? DateTime.now() : null,
                            );

                            if (existingEntry == null) {
                              await _firestoreService.createJournalEntry(userId, entry);
                            } else {
                              await _firestoreService.updateJournalEntry(userId, entry);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    existingEntry == null
                                        ? 'Entrada creada exitosamente'
                                        : 'Entrada actualizada',
                                  ),
                                ),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEntryDetails(JournalEntry entry, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
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
                      const Icon(Icons.calendar_today, color: Colors.purple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es_ES')
                              .format(entry.date),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddEntryDialog(userId, existingEntry: entry);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteEntry(entry, userId);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (entry.whatMadeHappy.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('😊', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 8),
                              Text(
                                '¿Qué me hizo feliz?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            entry.whatMadeHappy,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (entry.whatMadeSad.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('😔', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 8),
                              Text(
                                '¿Qué me hizo sentir triste?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            entry.whatMadeSad,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (entry.freeWriting.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('✍️', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 8),
                              Text(
                                'Escritura libre',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            entry.freeWriting,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (entry.updatedAt != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Última edición: ${DateFormat('d/M/yyyy HH:mm').format(entry.updatedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEntry(JournalEntry entry, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar entrada?'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta entrada del diario? Esta acción no se puede deshacer.',
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
      await _firestoreService.deleteJournalEntry(userId, entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrada eliminada')),
        );
      }
    }
  }
}

/**
 * Tarjeta de entrada de diario
 */
class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _JournalEntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.book,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d \'de\' MMMM', 'es_ES')
                              .format(entry.date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy').format(entry.date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: onTap,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.getPreview(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (entry.whatMadeHappy.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Text('😊', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            'Feliz',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  if (entry.whatMadeSad.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Text('😔', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            'Triste',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  if (entry.freeWriting.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Text('✍️', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            'Libre',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}