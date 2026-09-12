import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cuenta.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _supabase = Supabase.instance.client;
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _categoriaSeleccionada = 'Sueldo';
  final List<String> _categorias = ['Sueldo', 'Padres', 'Casa', 'Trabajito', 'Otro'];

  List<Cuenta> _cuentasTotales = [];
  String _tipoCuentaSeleccionado = 'banco';
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
        _cuentasTotales = response.map((e) => Cuenta.fromJson(e)).toList();
        _actualizarCuentasFiltradas();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar cuentas: $e');
    }
  }

  void _actualizarCuentasFiltradas() {
    final filtradas = _cuentasTotales.where((c) => c.tipo == _tipoCuentaSeleccionado).toList();
    setState(() {
      _cuentaDestino = filtradas.isNotEmpty ? filtradas.first : null;
    });
  }

  Future<void> _guardarIngreso() async {
    if (_montoController.text.isEmpty || _cuentaDestino == null) return;
    final monto = double.tryParse(_montoController.text) ?? 0.0;
    if (monto <= 0) return;

    try {
      await _supabase.from('movimientos').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'cuenta_id': _cuentaDestino!.id,
        'tipo': 'ingreso',
        'categoria': _categoriaSeleccionada,
        'descripcion': _descripcionController.text.trim(),
        'monto': monto,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingreso registrado'), backgroundColor: Colors.green));
        _montoController.clear();
        _descripcionController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint('Error al guardar ingreso: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.green));
    final cuentasFiltradas = _cuentasTotales.where((c) => c.tipo == _tipoCuentaSeleccionado).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.arrow_circle_up, color: Colors.green, size: 32),
                SizedBox(width: 10),
                Text('Registrar Ingreso', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto (S/)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money, color: Colors.green)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description, color: Colors.green)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoriaSeleccionada,
              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category, color: Colors.green)),
              items: _categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _categoriaSeleccionada = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipoCuentaSeleccionado,
              decoration: const InputDecoration(labelText: 'Tipo de Destino', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.green)),
              items: const [
                DropdownMenuItem(value: 'banco', child: Text('Cuenta Bancaria')),
                DropdownMenuItem(value: 'billetera', child: Text('Billetera Digital')),
                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
              ],
              onChanged: (val) {
                _tipoCuentaSeleccionado = val!;
                _actualizarCuentasFiltradas();
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Cuenta>(
              value: _cuentaDestino,
              decoration: const InputDecoration(labelText: 'Cuenta Específica', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance, color: Colors.green)),
              items: cuentasFiltradas.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
              onChanged: (val) => setState(() => _cuentaDestino = val),
              hint: cuentasFiltradas.isEmpty ? const Text('Sin cuentas de este tipo') : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: _guardarIngreso,
                child: const Text('Guardar Ingreso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}