import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  String? _categoriaSeleccionada;
  final List<String> _categorias = ['Sueldo', 'Proyectos Mecatrónicos', 'Pasantía', 'Otros'];

  String? _cuentaSeleccionada;
  final List<String> _cuentas = ['Efectivo', 'Cuenta Bancaria', 'Yape', 'Otras Billeteras', 'Tarjetas'];

  bool _guardando = false;

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardarIngreso() async {
    // Validamos que los campos no estén vacíos
    if (_montoController.text.isEmpty || _categoriaSeleccionada == null || _cuentaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa el monto, categoría y cuenta.')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final supabase = Supabase.instance.client;
      final usuarioId = supabase.auth.currentUser!.id;

      // Insertamos los datos reales en la tabla 'transacciones'
      await supabase.from('transacciones').insert({
        'user_id': usuarioId,
        'tipo': 'ingreso',
        'monto': double.parse(_montoController.text),
        'descripcion': _descripcionController.text,
        'categoria': _categoriaSeleccionada,
        'cuenta': _cuentaSeleccionada,
      });

      // Limpiamos el formulario
      _montoController.clear();
      _descripcionController.clear();
      setState(() {
        _categoriaSeleccionada = null;
        _cuentaSeleccionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Ingreso guardado exitosamente en la nube!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Registrar Nuevo Ingreso', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          TextField(
            controller: _montoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto (S/)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money, color: Colors.green)),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descripcionController,
            decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _categoriaSeleccionada,
            hint: const Text('Seleccionar Categoría'),
            decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.category, color: Colors.green)),
            items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _categoriaSeleccionada = val),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _cuentaSeleccionada,
            hint: const Text('Seleccionar Cuenta de Destino'),
            decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.green)),
            items: _cuentas.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _cuentaSeleccionada = val),
          ),
          const SizedBox(height: 32),

          _guardando 
            ? const Center(child: CircularProgressIndicator()) 
            : ElevatedButton(
                onPressed: _guardarIngreso,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Guardar Ingreso', style: TextStyle(fontSize: 16)),
              ),
        ],
      ),
    );
  }
}