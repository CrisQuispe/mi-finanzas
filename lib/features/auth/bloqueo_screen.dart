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
    // Esperamos un momento a que el frame gráfico termine de pintar antes de llamar al sensor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autenticar();
    });
  }

  Future<void> _autenticar() async {
    if (_autenticando) return;
    setState(() => _autenticando = true);

    try {
      final bool puedeAutenticarBiometria = await auth.canCheckBiometrics;
      final bool esDispositivoSoportado = await auth.isDeviceSupported();

      if (!puedeAutenticarBiometria || !esDispositivoSoportado) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        return;
      }

      final bool autenticado = await auth.authenticate(
        localizedReason: 'Autentícate para acceder a tus finanzas',
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
      if (mounted) {
        setState(() => _autenticando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade700,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 90, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Aplicación Bloqueada',
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Usa tu huella digital para continuar',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _autenticar,
                  icon: const Icon(Icons.fingerprint, size: 28),
                  label: const Text('Desbloquear con Huella', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}