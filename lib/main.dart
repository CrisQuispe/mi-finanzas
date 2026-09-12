import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializamos Supabase directamente con tus credenciales de producción
    await Supabase.initialize(
      url: 'https://hagqqtigamcglgdeszaj.supabase.co',
      anonKey: 'sb_publishable__6UQ5OJMtttyaiw-Q9oE0A_tO2OhrLE',
    );
  } catch (e) {
    debugPrint("Error al inicializar Supabase: $e");
  }

  runApp(const MiFinanzasApp());
}

class MiFinanzasApp extends StatelessWidget {
  const MiFinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Finanzas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificamos si Supabase se inicializó correctamente
    try {
      final supabaseInitialized = Supabase.instance.client;
      
      return StreamBuilder<AuthState>(
        stream: supabaseInitialized.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            );
          }
          
          final session = snapshot.hasData ? snapshot.data!.session : null;
          if (session != null) {
            return const HomeScreen();
          }
          
          return const LoginScreen();
        },
      );
    } catch (e) {
      // Si Supabase falla totalmente, mostramos una pantalla de error clara en lugar de negro
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error de inicialización en la base de datos:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }
  }
}