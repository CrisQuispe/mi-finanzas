import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cuenta.dart';
import '../deudas/deudas_screen.dart';
import '../transactions/transfer_screen.dart'; // Importante para el botón de transferencia

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  List<Cuenta> _cuentas = [];
  Map<String, double> _saldosActuales = {}; 
  double _saldoTotal = 0.0;
  double _totalMeDeben = 0.0;
  double _totalYoDebo = 0.0;
  bool _isLoading = true;
  
  // Variable para controlar la visibilidad solo del saldo principal
  bool _ocultarSaldo = true; 

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final cuentasData = await _supabase.from('cuentas').select().order('created_at');
      final movimientosData = await _supabase.from('movimientos').select();
      final deudasData = await _supabase.from('deudas').select();

      final cuentas = cuentasData.map((e) => Cuenta.fromJson(e)).toList();
      Map<String, double> saldosCalculados = {};
      double granTotal = 0.0;

      for (var c in cuentas) {
        saldosCalculados[c.id!] = c.saldoInicial;
      }

      for (var m in movimientosData) {
        String cuentaId = m['cuenta_id'];
        double monto = (m['monto'] as num).toDouble();
        String tipo = m['tipo'];

        if (saldosCalculados.containsKey(cuentaId)) {
          if (tipo == 'ingreso') saldosCalculados[cuentaId] = saldosCalculados[cuentaId]! + monto;
          if (tipo == 'gasto') saldosCalculados[cuentaId] = saldosCalculados[cuentaId]! - monto;
        }
      }

      for (var s in saldosCalculados.values) {
        granTotal += s;
      }

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

  // NUEVO: Función para mostrar los logos oficiales
  Widget _obtenerLogoImagen(String nombre) {
    String rutaImagen = '';
    
    if (nombre == 'Yape') rutaImagen = 'assets/logos/yape.png';
    else if (nombre == 'Plin') rutaImagen = 'assets/logos/plin.png';
    else if (nombre == 'BCP') rutaImagen = 'assets/logos/bcp.png';
    else if (nombre == 'Banco de la Nación') rutaImagen = 'assets/logos/nacion.png';
    else if (nombre == 'Efectivo') rutaImagen = 'assets/logos/efectivo.png';

    if (rutaImagen.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: AssetImage(rutaImagen), fit: BoxFit.cover),
          color: Colors.white,
        ),
      );
    }
    return CircleAvatar(backgroundColor: Colors.grey.shade300, child: const Icon(Icons.account_balance_wallet, color: Colors.black54));
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
            // TARJETA DE SALDO TOTAL (Se oculta con el botón)
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
                  Text(
                    _ocultarSaldo ? 'S/ ****' : 'S/ ${_saldoTotal.toStringAsFixed(2)}', 
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _ocultarSaldo = !_ocultarSaldo;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_ocultarSaldo ? Icons.visibility : Icons.visibility_off, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(_ocultarSaldo ? 'Mostrar saldo' : 'Ocultar saldo', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // DESGLOSE POR CUENTA (Siempre visible, ahora con logos)
            const Text('Desglose por Cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_cuentas.isEmpty)
              const Text('Ve a Ajustes para registrar tus cuentas.')
            else
              ..._cuentas.map((c) {
                final saldoCalculado = _saldosActuales[c.id!] ?? 0.0;
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: _obtenerLogoImagen(c.nombre), // AQUÍ SE APLICA EL LOGO
                    title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c.tipo.toUpperCase(), style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      'S/ ${saldoCalculado.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700)
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            
            // BOTÓN DE TRANSFERENCIA
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TransferScreen())).then((_) => _cargarDatos());
                },
                icon: const Icon(Icons.sync_alt, color: Colors.blue),
                label: const Text('Transferir entre mis cuentas', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(backgroundColor: Colors.blue.shade50, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
            ),
            const SizedBox(height: 24),

            // DEUDAS
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
                          Text(
                            'S/ ${_totalMeDeben.toStringAsFixed(2)}', 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)
                          ),
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
                          Text(
                            'S/ ${_totalYoDebo.toStringAsFixed(2)}', 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)
                          ),
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