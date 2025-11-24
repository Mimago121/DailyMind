/**
 * DailyMind - Aplicación de bienestar y seguimiento de hábitos
 * 
 * Archivo principal que inicializa Firebase y configura la aplicación
 * Autor: [Tu nombre]
 * Fecha: Noviembre 2025
 */

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Asegurar que los widgets estén inicializados antes de Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase con las opciones de configuración
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

/**
 * Widget raíz de la aplicación
 * Configura el tema y el provider de autenticación
 */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider del servicio de autenticación
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'DailyMind',
        debugShowCheckedModeBanner: false,
        
        // Configuración de localización (idioma español)
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
        locale: const Locale('es', 'ES'),
        
        theme: ThemeData(
          primarySwatch: Colors.purple,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/**
 * Widget que decide qué pantalla mostrar según el estado de autenticación
 */
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Mostrar loading mientras se verifica la autenticación
    if (authService.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Si no hay usuario, mostrar login
    if (authService.currentUser == null) {
      return const LoginScreen();
    }
    
    // Si el usuario no ha completado onboarding, mostrarlo
    if (!authService.hasCompletedOnboarding) {
      return const OnboardingScreen();
    }
    
    // Usuario autenticado y con onboarding completado
    return const HomeScreen();
  }
}