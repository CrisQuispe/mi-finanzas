import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/cuenta.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _supabase = Supabase.instance.client;
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _categoriaSeleccionada = 'Transporte';
  // Categorías personalizadas solicitadas
  final List<String> _categorias = [
    'Transporte', 'Menú', 'Universidad', 'Golosina', 'Agua', 
    'Deporte', 'Spotify', 'Internet Claro', 'Internet casa', 
    'Suscripción', 'Otro'
  ];

  List<Cuenta> _cuentasTotales = [];
  String _tipoCuentaSeleccionado = 'banco';
  Cuenta? _cuentaOrigen;
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
      _cuentaOrigen = filtradas.isNotEmpty ? filtradas.first : null;
    });
  }

  Future<void> _guardarGasto() async {
    if (_montoController.text.isEmpty || _cuentaOrigen == null) return;
    final monto = double.tryParse(_montoController.text) ?? 0.0;
    if (monto <= 0) return;

    try {
      await _supabase.from('movimientos').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'cuenta_id': _cuentaOrigen!.id,
        'tipo': 'gasto', // Se marca como salida de dinero
        'categoria': _categoriaSeleccionada,
        'descripcion': _descripcionController.text.trim(),
        'monto': monto,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasto registrado'), backgroundColor: Colors.red));
        _montoController.clear();
        _descripcionController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint('Error al guardar gasto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.red));
    final cuentasFiltradas = _cuentasTotales.where((c) => c.tipo == _tipoCuentaSeleccionado).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.arrow_circle_down, color: Colors.red, size: 32),
                SizedBox(width: 10),
                Text('Registrar Gasto', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto (S/)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.money_off, color: Colors.red)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description, color: Colors.red)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoriaSeleccionada,
              decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder(), prefixIcon: Icon(Icons.shopping_cart, color: Colors.red)),
              items: _categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _categoriaSeleccionada = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipoCuentaSeleccionado,
              decoration: const InputDecoration(labelText: 'Tipo de Origen', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.red)),
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
              value: _cuentaOrigen,
              decoration: const InputDecoration(labelText: 'Cuenta Específica', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance, color: Colors.red)),
              items: cuentasFiltradas.map((c) => DropdownMenuItem(value: c, child: Text(c.nombre))).toList(),
              onChanged: (val) => setState(() => _cuentaOrigen = val),
              hint: cuentasFiltradas.isEmpty ? const Text('Sin cuentas de este tipo') : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: _guardarGasto,
                child: const Text('Guardar Gasto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}