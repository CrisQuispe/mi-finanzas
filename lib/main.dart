import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
      // Usamos AuthGate para decidir automáticamente qué pantalla mostrar
      home: const AuthGate(),
    );
  }
}

// Este componente vigila el estado de la sesión en tiempo real
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // Si hay una sesión activa, enviamos al usuario directo al Dashboard
        final session = snapshot.hasData ? snapshot.data!.session : null;
        if (session != null) {
          return const HomeScreen();
        }
        
        // Si no hay sesión, enviamos a la pantalla de Login
        return const LoginScreen();
      },
    );
  }
}