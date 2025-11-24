/**
 * Pantalla de Onboarding
 * Cuestionario inicial para nuevos usuarios
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  final List<String> _selectedGoals = [];
  final List<String> _selectedCategories = [];

  final List<Map<String, dynamic>> _goals = [
    {'id': 'happiness', 'title': 'Ser más feliz', 'icon': Icons.sentiment_very_satisfied},
    {'id': 'health', 'title': 'Mejorar mi salud', 'icon': Icons.favorite},
    {'id': 'productivity', 'title': 'Ser más productivo', 'icon': Icons.trending_up},
    {'id': 'mindfulness', 'title': 'Practicar mindfulness', 'icon': Icons.self_improvement},
    {'id': 'habits', 'title': 'Crear buenos hábitos', 'icon': Icons.check_circle},
    {'id': 'mood', 'title': 'Entender mis emociones', 'icon': Icons.psychology},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'id': 'health', 'title': 'Salud', 'icon': Icons.favorite, 'color': Colors.red},
    {'id': 'productivity', 'title': 'Productividad', 'icon': Icons.work, 'color': Colors.blue},
    {'id': 'wellness', 'title': 'Bienestar', 'icon': Icons.spa, 'color': Colors.green},
    {'id': 'personal', 'title': 'Personal', 'icon': Icons.person, 'color': Colors.purple},
  ];

  void _toggleGoal(String goalId) {
    setState(() {
      if (_selectedGoals.contains(goalId)) {
        _selectedGoals.remove(goalId);
      } else {
        _selectedGoals.add(goalId);
      }
    });
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'selectedGoals': _selectedGoals,
        'selectedCategories': _selectedCategories,
        'onboardingCompleted': true,
      });
      await authService.completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de progreso
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
            
            Expanded(
              child: _currentStep == 0
                  ? _buildWelcomeStep()
                  : _currentStep == 1
                      ? _buildGoalsStep()
                      : _buildCategoriesStep(),
            ),

            // Botones de navegación
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                        },
                        child: const Text('Atrás'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_currentStep < 2) {
                          setState(() {
                            _currentStep++;
                          });
                        } else {
                          await _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_currentStep == 2 ? 'Comenzar' : 'Siguiente'),
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

  Widget _buildWelcomeStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wb_sunny,
              size: 120,
              color: Colors.purple,
            ),
            const SizedBox(height: 32),
            const Text(
              '¡Bienvenido a DailyMind!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tu compañero personal para mejorar tu bienestar diario',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Vamos a personalizar tu experiencia con algunas preguntas rápidas',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            '¿Cuáles son tus objetivos?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona uno o varios',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = _selectedGoals.contains(goal['id']);
                
                return InkWell(
                  onTap: () => _toggleGoal(goal['id']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purple : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.purple : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          goal['icon'],
                          size: 48,
                          color: isSelected ? Colors.white : Colors.purple,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          goal['title'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            '¿Qué áreas quieres trabajar?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona las categorías que más te interesen',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategories.contains(category['id']);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: InkWell(
                    onTap: () => _toggleCategory(category['id']),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? category['color'].withOpacity(0.2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? category['color']
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: category['color'].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              category['icon'],
                              color: category['color'],
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              category['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: category['color'],
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}