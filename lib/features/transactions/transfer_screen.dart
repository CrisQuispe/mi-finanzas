import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/cuenta.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _supabase = Supabase.instance.client;
  final _montoController = TextEditingController();
  
  List<Cuenta> _cuentas = [];
  Cuenta? _cuentaOrigen;
  Cuenta? _cuentaDestino;
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

  Future<void> _realizarTransferencia() async {
    final monto = double.tryParse(_montoController.text) ?? 0.0;
    
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un monto válido')));
      return;
    }
    if (_cuentaOrigen == null || _cuentaDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona ambas cuentas')));
      return;
    }
    if (_cuentaOrigen!.id == _cuentaDestino!.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las cuentas deben ser diferentes')));
      return;
    }

    try {
      final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. Registrar salida de la cuenta origen
      await _supabase.from('movimientos').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'cuenta_id': _cuentaOrigen!.id,
        'tipo': 'gasto',
        'categoria': 'Transferencia',
        'descripcion': 'Transferencia hacia ${_cuentaDestino!.nombre}',
        'monto': monto,
        'fecha': fecha,
      });

      // 2. Registrar entrada a la cuenta destino
      await _supabase.from('movimientos').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'cuenta_id': _cuentaDestino!.id,
        'tipo': 'ingreso',
        'categoria': 'Transferencia',
        'descripcion': 'Transferencia desde ${_cuentaOrigen!.nombre}',
        'monto': monto,
        'fecha': fecha,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transferencia exitosa'), backgroundColor: Colors.blue));
        Navigator.pop(context); // Regresa al Dashboard
      }
    } catch (e) {
      debugPrint('Error en transferencia: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Transferir Dinero'), backgroundColor: Colors.blue.shade100),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mueve dinero entre tus propias cuentas (Ej: Retirar efectivo del banco).', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            DropdownButtonFormField<Cuenta>(
              value: _cuentaOrigen,
              decoration: const InputDecoration(labelText: 'Cuenta de Origen (De donde sale)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.arrow_upward, color: Colors.red)),
              items: _cuentas.map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} (${c.tipo})'))).toList(),
              onChanged: (val) => setState(() => _cuentaOrigen = val),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<Cuenta>(
              value: _cuentaDestino,
              decoration: const InputDecoration(labelText: 'Cuenta de Destino (A donde entra)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.arrow_downward, color: Colors.green)),
              items: _cuentas.map((c) => DropdownMenuItem(value: c, child: Text('${c.nombre} (${c.tipo})'))).toList(),
              onChanged: (val) => setState(() => _cuentaDestino = val),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto a transferir (S/)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sync_alt, color: Colors.blue)),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: _realizarTransferencia,
                child: const Text('Confirmar Transferencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}