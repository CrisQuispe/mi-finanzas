// Archivo: lib/features/ajustes/ajustes_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cuenta.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _supabase = Supabase.instance.client;
  List<Cuenta> _cuentas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCuentas();
  }

  Future<void> _cargarCuentas() async {
    try {
      final response = await _supabase.from('cuentas').select().order('created_at');
      setState(() {
        _cuentas = response.map((e) => Cuenta.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar cuentas: $e');
    }
  }

  void _mostrarDialogoNuevaCuenta() {
    final nombreController = TextEditingController();
    final saldoController = TextEditingController();
    String tipoSeleccionado = 'banco';
    String nombreSugerido = 'BCP';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Registrar Cuenta / Saldo Inicial'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
                      items: const [
                        DropdownMenuItem(value: 'banco', child: Text('Cuenta Bancaria')),
                        DropdownMenuItem(value: 'billetera', child: Text('Billetera Digital')),
                        DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          tipoSeleccionado = val!;
                          if (val == 'banco') nombreSugerido = 'BCP';
                          if (val == 'billetera') nombreSugerido = 'Yape';
                          if (val == 'efectivo') nombreSugerido = 'Efectivo';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (tipoSeleccionado == 'banco')
                      DropdownButtonFormField<String>(
                        value: nombreSugerido,
                        decoration: const InputDecoration(labelText: 'Banco'),
                        items: const [
                          DropdownMenuItem(value: 'BCP', child: Text('BCP')),
                          DropdownMenuItem(value: 'Banco de la Nación', child: Text('Banco de la Nación')),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (val) => setStateDialog(() => nombreSugerido = val!),
                      ),
                    if (tipoSeleccionado == 'billetera')
                      DropdownButtonFormField<String>(
                        value: nombreSugerido,
                        decoration: const InputDecoration(labelText: 'Billetera'),
                        items: const [
                          DropdownMenuItem(value: 'Yape', child: Text('Yape')),
                          DropdownMenuItem(value: 'Plin', child: Text('Plin')),
                          DropdownMenuItem(value: 'Agora', child: Text('Agora')),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (val) => setStateDialog(() => nombreSugerido = val!),
                      ),
                    if (nombreSugerido == 'Otro')
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextField(
                          controller: nombreController,
                          decoration: const InputDecoration(labelText: 'Escribe el nombre'),
                        ),
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: saldoController,
                      decoration: const InputDecoration(labelText: 'Saldo Inicial (S/)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    final nombreFinal = nombreSugerido == 'Otro' ? nombreController.text : nombreSugerido;
                    final saldo = double.tryParse(saldoController.text) ?? 0.0;
                    
                    final nuevaCuenta = Cuenta(
                      nombre: nombreFinal,
                      tipo: tipoSeleccionado,
                      saldoInicial: saldo,
                    );

                    await _supabase.from('cuentas').insert(nuevaCuenta.toJson());
                    if (context.mounted) Navigator.pop(context);
                    _cargarCuentas(); // Recarga la lista
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuentas y Saldos'),
        backgroundColor: Colors.green.shade100,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _cuentas.isEmpty
              ? const Center(child: Text('No has registrado ninguna cuenta aún.'))
              : ListView.builder(
                  itemCount: _cuentas.length,
                  itemBuilder: (context, index) {
                    final c = _cuentas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        subtitle: Text(c.tipo.toUpperCase()),
                        trailing: Text('S/ ${c.saldoInicial.toStringAsFixed(2)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevaCuenta,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cuenta'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}