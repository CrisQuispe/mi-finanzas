import 'package:flutter/material.dart';
import '../ajustes/ajustes_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/income_screen.dart';
import '../transactions/expense_screen.dart';
import '../transactions/movimientos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceSeleccionado = 0;

  // Nuevo orden exacto de las pantallas
  final List<Widget> _pantallas = [
    const DashboardScreen(),     // 0: Resumen
    const MovimientosScreen(),   // 1: Movimientos
    const IncomeScreen(),        // 2: Ingresos
    const ExpenseScreen(),       // 3: Gastos
    const AjustesScreen(),       // 4: Ajustes
  ];

  void _alTocarOpcion(int index) {
    setState(() {
      _indiceSeleccionado = index;
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
      body: _pantallas[_indiceSeleccionado],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceSeleccionado,
        onDestinationSelected: _alTocarOpcion,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Resumen'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Movimientos'),
          NavigationDestination(icon: Icon(Icons.arrow_upward_outlined), selectedIcon: Icon(Icons.arrow_upward), label: 'Ingresos'),
          NavigationDestination(icon: Icon(Icons.arrow_downward_outlined), selectedIcon: Icon(Icons.arrow_downward), label: 'Gastos'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}