import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cuenta.dart';
import '../deudas/deudas_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  List<Cuenta> _cuentas = [];
  Map<String, double> _saldosActuales = {}; // Aquí guardaremos la matemática en vivo
  double _saldoTotal = 0.0;
  double _totalMeDeben = 0.0;
  double _totalYoDebo = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // 1. Traer cuentas, movimientos y deudas
      final cuentasData = await _supabase.from('cuentas').select().order('created_at');
      final movimientosData = await _supabase.from('movimientos').select();
      final deudasData = await _supabase.from('deudas').select();

      final cuentas = cuentasData.map((e) => Cuenta.fromJson(e)).toList();
      Map<String, double> saldosCalculados = {};
      double granTotal = 0.0;

      // 2. Asignar saldo inicial
      for (var c in cuentas) {
        saldosCalculados[c.id!] = c.saldoInicial;
      }

      // 3. Procesar las sumas y restas cruzadas
      for (var m in movimientosData) {
        String cuentaId = m['cuenta_id'];
        double monto = (m['monto'] as num).toDouble();
        String tipo = m['tipo'];

        if (saldosCalculados.containsKey(cuentaId)) {
          if (tipo == 'ingreso') saldosCalculados[cuentaId] = saldosCalculados[cuentaId]! + monto;
          if (tipo == 'gasto') saldosCalculados[cuentaId] = saldosCalculados[cuentaId]! - monto;
        }
      }

      // 4. Calcular el gran total sumando las cuentas
      for (var s in saldosCalculados.values) {
        granTotal += s;
      }

      // 5. Contar deudas pendientes
      double meDeben = 0;
      double yoDebo = 0;
      for (var d in deudasData) {
        if (d['pagada'] == false) {
          if (d['tipo'] == 'me_deben') meDeben += (d['monto'] as num).toDouble();
          if (d['tipo'] == 'yo_debo') yoDebo += (d['monto'] as num).toDouble();
        }
      }

      setState(() {
        _cuentas = cuentas;
        _saldosActuales = saldosCalculados;
        _saldoTotal = granTotal;
        _totalMeDeben = meDeben;
        _totalYoDebo = yoDebo;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.green));

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade500]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Text('Saldo Total Disponible', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('S/ ${_saldoTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Desglose por Cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_cuentas.isEmpty)
              const Text('Ve a Ajustes para registrar tus cuentas.')
            else
              ..._cuentas.map((c) {
                // Obtenemos el saldo que acabamos de calcular matemáticamente
                final saldoCalculado = _saldosActuales[c.id!] ?? 0.0;
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: Icon(
                        c.tipo == 'banco' ? Icons.account_balance :
                        c.tipo == 'billetera' ? Icons.phone_android : Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c.tipo.toUpperCase(), style: const TextStyle(fontSize: 12)),
                    trailing: Text('S/ ${saldoCalculado.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  ),
                );
              }),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Resumen de Deudas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DeudasScreen())).then((_) => _cargarDatos());
                  },
                  child: const Text('Gestionar', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Me deben', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('S/ ${_totalMeDeben.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Yo debo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('S/ ${_totalYoDebo.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}