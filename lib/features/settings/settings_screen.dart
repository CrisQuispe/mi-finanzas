import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.settings, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Ajustes de Cuenta', 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 48),
          
          // Botón para cerrar sesión y limpiar la caché de Supabase
          ElevatedButton.icon(
            onPressed: () async {
              // Esta línea borra la sesión de Supabase del celular/navegador
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}