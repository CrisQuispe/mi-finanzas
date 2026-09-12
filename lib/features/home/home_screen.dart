import '../settings/settings_screen.dart';
import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/income_screen.dart';
import '../transactions/expense_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Esta variable guarda el índice de la pestaña seleccionada (inicia en 0)
  int _indiceSeleccionado = 0;

  // Lista temporal de pantallas. En las siguientes fases reemplazaremos 
  // estos textos por las pantallas reales (Dashboard, Registro, etc.)
 final List<Widget> _pantallas = const [
  DashboardScreen(),
  IncomeScreen(),
  ExpenseScreen(),
  SettingsScreen(), // <--- Debe decir exactamente esto, sin Text()
];

  // Función que se ejecuta al tocar un ícono del menú
  void _alTocarOpcion(int index) {
    setState(() {
      _indiceSeleccionado = index; // Actualiza el estado con el nuevo índice
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Finanzas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      // Muestra la pantalla correspondiente al índice actual
      body: _pantallas[_indiceSeleccionado],
      
      // Barra de navegación inferior
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceSeleccionado,
        onDestinationSelected: _alTocarOpcion,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.arrow_upward_outlined), selectedIcon: Icon(Icons.arrow_upward), label: 'Ingresos'),
          NavigationDestination(icon: Icon(Icons.arrow_downward_outlined), selectedIcon: Icon(Icons.arrow_downward), label: 'Gastos'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}