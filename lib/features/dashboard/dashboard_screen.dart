import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Función para obtener las transacciones desde la base de datos
  Future<List<Map<String, dynamic>>> _cargarTransacciones() async {
    final supabase = Supabase.instance.client;
    final respuesta = await supabase
        .from('transacciones')
        .select()
        .order('fecha_creacion', ascending: false);
    
    return List<Map<String, dynamic>>.from(respuesta);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _cargarTransacciones(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
        }

        final transacciones = snapshot.data ?? [];

        double totalIngresos = 0;
        double totalGastos = 0;

        for (var t in transacciones) {
          if (t['tipo'] == 'ingreso') {
            totalIngresos += (t['monto'] as num).toDouble();
          } else if (t['tipo'] == 'gasto') {
            totalGastos += (t['monto'] as num).toDouble();
          }
        }

        final saldoTotal = totalIngresos - totalGastos;

        // RefreshIndicator permite deslizar hacia abajo para actualizar los datos
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _construirTarjetaSaldo(context, saldoTotal),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(child: _construirTarjetaMini('Ingresos', 'S/ ${totalIngresos.toStringAsFixed(2)}', Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _construirTarjetaMini('Gastos', 'S/ ${totalGastos.toStringAsFixed(2)}', Colors.red)),
                  ],
                ),
                const SizedBox(height: 32),

                const Text(
                  'Últimos movimientos (Desliza hacia abajo para actualizar)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),

                if (transacciones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aún no tienes movimientos registrados.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...transacciones.take(5).map((t) {
                    final esIngreso = t['tipo'] == 'ingreso';
                    return _construirItemMovimiento(
                      t['descripcion'] ?? 'Sin descripción',
                      t['categoria'] ?? 'General',
                      '${esIngreso ? '+' : '-'} S/ ${(t['monto'] as num).toStringAsFixed(2)}',
                      esIngreso ? Colors.green : Colors.red,
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirTarjetaSaldo(BuildContext context, double saldo) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saldo Total', style: TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(
              'S/ ${saldo.toStringAsFixed(2)}', 
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black)
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaMini(String titulo, String monto, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(titulo, style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(monto, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _construirItemMovimiento(String titulo, String subtitulo, String monto, Color colorMonto) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorMonto.withOpacity(0.1),
        child: Icon(
          colorMonto == Colors.green ? Icons.arrow_upward : Icons.arrow_downward,
          color: colorMonto,
        ),
      ),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitulo),
      trailing: Text(monto, style: TextStyle(fontWeight: FontWeight.bold, color: colorMonto, fontSize: 16)),
    );
  }
}