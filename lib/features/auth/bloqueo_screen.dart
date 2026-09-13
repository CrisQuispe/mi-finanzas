import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../home/home_screen.dart';

class BloqueoScreen extends StatefulWidget {
  const BloqueoScreen({super.key});

  @override
  State<BloqueoScreen> createState() => _BloqueoScreenState();
}

class _BloqueoScreenState extends State<BloqueoScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _autenticando = false;

  @override
  void initState() {
    super.initState();
    _autenticar();
  }

  Future<void> _autenticar() async {
    setState(() => _autenticando = true);
    try {
      final bool puedeAutenticarBiometria = await auth.canCheckBiometrics;
      if (!puedeAutenticarBiometria) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        return;
      }

      final bool autenticado = await auth.authenticate(
        localizedReason: 'Usa tu huella para acceder a tus finanzas',
      );

      if (autenticado && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error de biometría: $e');
    } finally {
      if (mounted) setState(() => _autenticando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text('App Bloqueada', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _autenticar,
              icon: const Icon(Icons.fingerprint, size: 30),
              label: const Text('Desbloquear con Huella', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade700,
              ),
            )
          ],
        ),
      ),
    );
  }
}