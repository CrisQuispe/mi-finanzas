// Archivo: lib/features/deudas/deudas_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/deuda.dart';
import '../../models/cuenta.dart';

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key});

  @override
  State<DeudasScreen> createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  final _supabase = Supabase.instance.client;
  List<Deuda> _deudas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDeudas();
  }

  Future<void> _cargarDeudas() async {
    try {
      final response = await _supabase.from('deudas').select().order('created_at', ascending: false);
      setState(() {
        _deudas = response.map((e) => Deuda.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar deudas: $e');
    }
  }

  void _mostrarDialogoNuevaDeuda() {
    final personaController = TextEditingController();
    final montoController = TextEditingController();
    String tipoSeleccionado = 'me_deben';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Registrar Deuda'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: const [
                        DropdownMenuItem(value: 'me_deben', child: Text('Me deben dinero')),
                        DropdownMenuItem(value: 'yo_debo', child: Text('Yo debo dinero')),
                      ],
                      onChanged: (val) => setStateDialog(() => tipoSeleccionado = val!),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: personaController,
                      decoration: const InputDecoration(labelText: 'Nombre de la persona', hintText: 'Ej: Noemi, Tío Héctor, etc.'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto (S/)', prefixIcon: Icon(Icons.attach_money)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    final monto = double.tryParse(montoController.text) ?? 0.0;
                    if (personaController.text.isEmpty || monto <= 0) return;

                    await _supabase.from('deudas').insert({
                      'user_id': _supabase.auth.currentUser!.id,
                      'tipo': tipoSeleccionado,
                      'persona': personaController.text.trim(),
                      'monto': monto,
                    });
                    if (context.mounted) Navigator.pop(context);
                    _cargarDeudas();
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _procesarPagoDeuda(Deuda deuda) async {
    // 1. Cargar las cuentas disponibles para elegir con cuál se pagó
    final cuentasData = await _supabase.from('cuentas').select();
    final cuentas = cuentasData.map((e) => Cuenta.fromJson(e)).toList();
    
    if (cuentas.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes cuentas registradas')));
      return;
    }

    Cuenta? cuentaSeleccionada = cuentas.first;

    if (!context.mounted) return;

    // 2. Mostrar diálogo preguntando por dónde se pagó
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(deuda.tipo == 'me_deben' ? '¿A dónde te pagaron?' : '¿De dónde pagaste?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Monto: S/ ${deuda.monto.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Cuenta>(
                    value: cuentaSeleccionada,
                    decoration: const InputDecoration(labelText: 'Cuenta afectada', border: OutlineInputBorder()),
                    items: cuentas.map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} (${c.tipo})'))).toList(),
                    onChanged: (val) => setStateDialog(() => cuentaSeleccionada = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    if (cuentaSeleccionada == null) return;
                    
                    // 3. Actualizar la deuda como pagada
                    await _supabase.from('deudas').update({
                      'pagada': true,
                      'cuenta_pago_id': cuentaSeleccionada!.id,
                    }).eq('id', deuda.id);

                    // 4. Generar el movimiento automáticamente
                    final tipoMovimiento = deuda.tipo == 'me_deben' ? 'ingreso' : 'gasto';
                    final descMovimiento = deuda.tipo == 'me_deben' ? 'Cobro de deuda a ${deuda.persona}' : 'Pago de deuda a ${deuda.persona}';

                    await _supabase.from('movimientos').insert({
                      'user_id': _supabase.auth.currentUser!.id,
                      'cuenta_id': cuentaSeleccionada!.id,
                      'tipo': tipoMovimiento,
                      'categoria': 'Deuda',
                      'descripcion': descMovimiento,
                      'monto': deuda.monto,
                    });

                    if (context.mounted) Navigator.pop(context);
                    _cargarDeudas();
                  },
                  child: const Text('Confirmar Pago', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Deudas'), backgroundColor: Colors.blue.shade100),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _deudas.length,
            itemBuilder: (context, index) {
              final deuda = _deudas[index];
              final esMio = deuda.tipo == 'me_deben';
              
              return Card(
                color: deuda.pagada ? Colors.grey.shade200 : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: deuda.pagada ? Colors.grey : (esMio ? Colors.blue.shade100 : Colors.red.shade100),
                    child: Icon(esMio ? Icons.arrow_downward : Icons.arrow_upward, color: deuda.pagada ? Colors.white : (esMio ? Colors.blue : Colors.red)),
                  ),
                  title: Text(deuda.persona, style: TextStyle(fontWeight: FontWeight.bold, decoration: deuda.pagada ? TextDecoration.lineThrough : null)),
                  subtitle: Text(esMio ? 'Me debe' : 'Le debo'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('S/ ${deuda.monto.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: deuda.pagada ? Colors.grey : Colors.black)),
                      if (!deuda.pagada) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                          onPressed: () => _procesarPagoDeuda(deuda),
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevaDeuda,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Deuda'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}