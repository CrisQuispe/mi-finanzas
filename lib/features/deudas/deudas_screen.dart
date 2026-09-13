import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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
  List<Cuenta> _cuentas = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final deudasResponse = await _supabase.from('deudas').select().order('created_at', ascending: false);
      final cuentasResponse = await _supabase.from('cuentas').select().order('created_at');
      
      setState(() {
        _deudas = deudasResponse.map((e) => Deuda.fromJson(e)).toList();
        _cuentas = cuentasResponse.map((e) => Cuenta.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
    }
  }

  Future<void> _eliminarDeuda(Deuda deuda) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Deuda'),
        content: const Text('¿Seguro que deseas eliminar esta deuda?\n\nNota: Si ya se generó un registro en tu pestaña de Movimientos, deberás borrarlo manualmente de allí para que tus saldos cuadren.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _supabase.from('deudas').delete().eq('id', deuda.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deuda eliminada'), backgroundColor: Colors.red));
        _cargarDatos();
      }
    } catch (e) {
      debugPrint('Error al eliminar deuda: $e');
    }
  }

  Future<void> _editarDeuda(Deuda deuda) async {
    final personaController = TextEditingController(text: deuda.persona);
    final montoController = TextEditingController(text: deuda.monto.toString());

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Deuda'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: personaController,
                decoration: const InputDecoration(labelText: 'Nombre de la persona'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto (S/)'),
              ),
              const SizedBox(height: 16),
              const Text('Nota: Editar el monto aquí no modificará el registro en tu Historial. Ajusta ese movimiento manualmente.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final nuevoMonto = double.tryParse(montoController.text) ?? deuda.monto;
    final nuevaPersona = personaController.text.trim();

    if (nuevaPersona.isEmpty || nuevoMonto <= 0) return;

    try {
      await _supabase.from('deudas').update({
        'persona': nuevaPersona,
        'monto': nuevoMonto,
      }).eq('id', deuda.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deuda actualizada'), backgroundColor: Colors.green));
        _cargarDatos();
      }
    } catch (e) {
      debugPrint('Error al actualizar deuda: $e');
    }
  }

  void _mostrarDialogoNuevaDeuda() {
    final personaController = TextEditingController();
    final montoController = TextEditingController();
    String tipoSeleccionado = 'me_deben';
    Cuenta? cuentaSeleccionada = _cuentas.isNotEmpty ? _cuentas.first : null;
    
    // NUEVO: Variable para controlar si es deuda antigua
    bool esDeudaAntigua = false;

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
                        DropdownMenuItem(value: 'me_deben', child: Text('Me deben dinero (Presté)')),
                        DropdownMenuItem(value: 'yo_debo', child: Text('Yo debo dinero (Me prestaron)')),
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
                    const SizedBox(height: 10),
                    
                    // NUEVO: Switch para marcar como deuda del pasado
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Es una deuda antigua (Solo registrar, no restar del saldo actual)', style: TextStyle(fontSize: 13)),
                      value: esDeudaAntigua,
                      activeColor: Colors.blue,
                      onChanged: (bool value) {
                        setStateDialog(() {
                          esDeudaAntigua = value;
                        });
                      },
                    ),

                    // Ocultamos el selector de cuenta si es deuda antigua
                    if (!esDeudaAntigua) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Cuenta>(
                        value: cuentaSeleccionada,
                        decoration: InputDecoration(
                          labelText: tipoSeleccionado == 'me_deben' ? '¿De dónde salió el dinero?' : '¿A dónde ingresó el dinero?',
                          border: const OutlineInputBorder()
                        ),
                        items: _cuentas.map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} (${c.tipo})'))).toList(),
                        onChanged: (val) => setStateDialog(() => cuentaSeleccionada = val),
                        hint: _cuentas.isEmpty ? const Text('No hay cuentas registradas') : null,
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    final monto = double.tryParse(montoController.text) ?? 0.0;
                    
                    // Validaciones
                    if (personaController.text.isEmpty || monto <= 0) return;
                    if (!esDeudaAntigua && cuentaSeleccionada == null) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una cuenta o marca como deuda antigua')));
                       return;
                    }

                    // 1. Guardar la Deuda siempre
                    await _supabase.from('deudas').insert({
                      'user_id': _supabase.auth.currentUser!.id,
                      'tipo': tipoSeleccionado,
                      'persona': personaController.text.trim(),
                      'monto': monto,
                    });

                    // 2. Generar el movimiento SOLO si NO es deuda antigua
                    if (!esDeudaAntigua) {
                      final tipoMovimiento = tipoSeleccionado == 'me_deben' ? 'gasto' : 'ingreso';
                      final descMovimiento = tipoSeleccionado == 'me_deben' 
                          ? 'Préstamo otorgado a ${personaController.text.trim()}' 
                          : 'Préstamo recibido de ${personaController.text.trim()}';

                      await _supabase.from('movimientos').insert({
                        'user_id': _supabase.auth.currentUser!.id,
                        'cuenta_id': cuentaSeleccionada!.id,
                        'tipo': tipoMovimiento,
                        'categoria': 'Préstamo',
                        'descripcion': descMovimiento,
                        'monto': monto,
                        'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      });
                    }

                    if (context.mounted) Navigator.pop(context);
                    _cargarDatos();
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
    if (_cuentas.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes cuentas registradas')));
      return;
    }

    Cuenta? cuentaSeleccionada = _cuentas.first;

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
                    items: _cuentas.map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} (${c.tipo})'))).toList(),
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
                    
                    await _supabase.from('deudas').update({
                      'pagada': true,
                      'cuenta_pago_id': cuentaSeleccionada!.id,
                    }).eq('id', deuda.id);

                    final tipoMovimiento = deuda.tipo == 'me_deben' ? 'ingreso' : 'gasto';
                    final descMovimiento = deuda.tipo == 'me_deben' ? 'Cobro de deuda a ${deuda.persona}' : 'Pago de deuda a ${deuda.persona}';

                    await _supabase.from('movimientos').insert({
                      'user_id': _supabase.auth.currentUser!.id,
                      'cuenta_id': cuentaSeleccionada!.id,
                      'tipo': tipoMovimiento,
                      'categoria': 'Deuda',
                      'descripcion': descMovimiento,
                      'monto': deuda.monto,
                      'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    });

                    if (context.mounted) Navigator.pop(context);
                    _cargarDatos();
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
                        const SizedBox(width: 5),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                          onPressed: () => _procesarPagoDeuda(deuda),
                        ),
                      ],
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'editar') _editarDeuda(deuda);
                          if (value == 'eliminar') _eliminarDeuda(deuda);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'editar', child: Text('Editar')),
                          const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                        ],
                      ),
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