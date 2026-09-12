import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/movimiento.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final _supabase = Supabase.instance.client;
  List<Movimiento> _movimientos = [];
  bool _isLoading = true;
  
  // Por defecto es el día de hoy
  DateTime? _fechaFiltro;
  String _tipoFiltro = 'dia'; 

  @override
  void initState() {
    super.initState();
    _fechaFiltro = DateTime.now(); // Carga el día actual por defecto
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase.from('movimientos').select('*, cuentas(nombre)');
      
      if (_fechaFiltro != null) {
        if (_tipoFiltro == 'dia') {
          final fechaStr = DateFormat('yyyy-MM-dd').format(_fechaFiltro!);
          query = query.eq('fecha', fechaStr);
        } else {
          final inicioMes = DateTime(_fechaFiltro!.year, _fechaFiltro!.month, 1);
          final finMes = DateTime(_fechaFiltro!.year, _fechaFiltro!.month + 1, 0);
          query = query.gte('fecha', DateFormat('yyyy-MM-dd').format(inicioMes))
                       .lte('fecha', DateFormat('yyyy-MM-dd').format(finMes));
        }
      }

      final response = await query.order('fecha', ascending: false).order('created_at', ascending: false);
      
      setState(() {
        _movimientos = response.map((e) => Movimiento.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: _tipoFiltro == 'mes' ? 'Selecciona cualquier día del mes deseado' : 'Selecciona un día',
    );
    if (seleccion != null) {
      setState(() => _fechaFiltro = seleccion);
      _cargarMovimientos();
    }
  }

  void _mostrarDialogoEdicion(Movimiento mov) {
    final montoController = TextEditingController(text: mov.monto.toString());
    final descController = TextEditingController(text: mov.descripcion ?? '');
    
    final categoriasIngreso = ['Sueldo', 'Padres', 'Casa', 'Trabajito', 'Otro'];
    final categoriasGasto = ['Transporte', 'Menú', 'Universidad', 'Golosina', 'Agua', 'Deporte', 'Spotify', 'Internet Claro', 'Internet casa', 'Suscripción', 'Otro'];
    
    String catSeleccionada = mov.categoria;
    final listaCategorias = mov.tipo == 'ingreso' ? categoriasIngreso : categoriasGasto;
    
    if (!listaCategorias.contains(catSeleccionada)) catSeleccionada = listaCategorias.last;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Editar ${mov.tipo.toUpperCase()}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: catSeleccionada,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: listaCategorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setStateDialog(() => catSeleccionada = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _supabase.from('movimientos').delete().eq('id', mov.id);
                    if (context.mounted) Navigator.pop(context);
                    _cargarMovimientos();
                  },
                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final nuevoMonto = double.tryParse(montoController.text) ?? mov.monto;
                    await _supabase.from('movimientos').update({
                      'monto': nuevoMonto,
                      'descripcion': descController.text.trim(),
                      'categoria': catSeleccionada,
                    }).eq('id', mov.id);
                    if (context.mounted) Navigator.pop(context);
                    _cargarMovimientos();
                  },
                  child: const Text('Guardar'),
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
    // Texto dinámico para el botón según el tipo de filtro
    String textoFecha = 'Seleccionar fecha';
    if (_fechaFiltro != null) {
      textoFecha = _tipoFiltro == 'dia' 
          ? DateFormat('dd/MM/yyyy').format(_fechaFiltro!)
          : DateFormat('MM/yyyy').format(_fechaFiltro!); // Muestra solo Mes y Año
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Movimientos', style: TextStyle(fontSize: 20)),
        backgroundColor: Colors.green.shade100,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _tipoFiltro,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'dia', child: Text('Por Día Exacto')),
                    DropdownMenuItem(value: 'mes', child: Text('Por Mes Completo')),
                  ],
                  onChanged: (val) {
                    setState(() => _tipoFiltro = val!);
                    _cargarMovimientos();
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month, color: Colors.green),
                  label: Text(textoFecha),
                  onPressed: () => _seleccionarFecha(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : _movimientos.isEmpty
                ? const Center(child: Text('Sin movimientos', style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
                    itemCount: _movimientos.length,
                    itemBuilder: (context, index) {
                      final mov = _movimientos[index];
                      final esIngreso = mov.tipo == 'ingreso';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: ListTile(
                          onTap: () => _mostrarDialogoEdicion(mov),
                          leading: CircleAvatar(
                            backgroundColor: esIngreso ? Colors.green.shade50 : Colors.red.shade50,
                            child: Icon(esIngreso ? Icons.arrow_upward : Icons.arrow_downward, 
                                        color: esIngreso ? Colors.green : Colors.red),
                          ),
                          title: Text(mov.categoria, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${mov.cuentaNombre} - ${mov.descripcion ?? ''}\n${DateFormat('dd MMM yyyy').format(mov.fecha)}'),
                          isThreeLine: true,
                          trailing: Text(
                            '${esIngreso ? '+' : '-'} S/ ${mov.monto.toStringAsFixed(2)}',
                            style: TextStyle(color: esIngreso ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}