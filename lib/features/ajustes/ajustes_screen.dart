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

  // Mapa que define qué opciones mostrar según el tipo elegido
  final Map<String, List<String>> _opcionesPorTipo = {
    'banco': ['BCP', 'Banco de la Nación'],
    'billetera': ['Yape', 'Plin'],
    'efectivo': ['Efectivo'],
  };

  @override
  void initState() {
    super.initState();
    _cargarCuentas();
  }

  Future<void> _cargarCuentas() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('cuentas').select().order('created_at');
      setState(() {
        _cuentas = response.map((e) => Cuenta.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar cuentas: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarCuenta(Cuenta cuenta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: Text('¿Estás seguro de que deseas eliminar "${cuenta.nombre}"?'),
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
      await _supabase.from('cuentas').delete().eq('id', cuenta.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta eliminada'), backgroundColor: Colors.red));
        _cargarCuentas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se puede eliminar: Ya tiene movimientos registrados.'), 
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // NUEVA FUNCIÓN: Editar el Saldo Inicial
  Future<void> _editarSaldo(Cuenta cuenta) async {
    final saldoController = TextEditingController(text: cuenta.saldoInicial.toString());
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Saldo - ${cuenta.nombre}'),
        content: TextField(
          controller: saldoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Nuevo Saldo Inicial (S/)', border: OutlineInputBorder()),
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
    
    final nuevoSaldo = double.tryParse(saldoController.text) ?? cuenta.saldoInicial;

    try {
      await _supabase.from('cuentas').update({'saldo_inicial': nuevoSaldo}).eq('id', cuenta.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo actualizado'), backgroundColor: Colors.green));
        _cargarCuentas();
      }
    } catch (e) {
      debugPrint('Error al actualizar saldo: $e');
    }
  }

  // NUEVA FUNCIÓN: Lee las imágenes locales descargadas en el Paso 1
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
          color: Colors.white, // Fondo blanco por si el logo tiene transparencias
        ),
      );
    }
    // Respaldo en caso de que falte alguna imagen
    return CircleAvatar(backgroundColor: Colors.grey.shade300, child: const Icon(Icons.account_balance_wallet, color: Colors.black54));
  }

  void _mostrarDialogoNuevaCuenta() {
    String tipoSeleccionado = 'banco';
    String entidadSeleccionada = _opcionesPorTipo['banco']!.first; // Selecciona BCP por defecto
    final saldoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nueva Cuenta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SELECTOR 1: TIPO DE CUENTA
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Tipo de Cuenta'),
                      items: const [
                        DropdownMenuItem(value: 'banco', child: Text('Cuenta Bancaria')),
                        DropdownMenuItem(value: 'billetera', child: Text('Billetera Digital')),
                        DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          tipoSeleccionado = val!;
                          // Al cambiar el tipo, se actualiza automáticamente la entidad a la primera opción de la nueva lista
                          entidadSeleccionada = _opcionesPorTipo[tipoSeleccionado]!.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // SELECTOR 2: ENTIDAD (Depende del primero)
                    DropdownButtonFormField<String>(
                      value: entidadSeleccionada,
                      decoration: const InputDecoration(labelText: 'Entidad / Banco'),
                      items: _opcionesPorTipo[tipoSeleccionado]!.map((entidad) => DropdownMenuItem(
                        value: entidad, 
                        child: Text(entidad)
                      )).toList(),
                      onChanged: (val) => setStateDialog(() => entidadSeleccionada = val!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: saldoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Saldo Inicial (S/)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    final saldo = double.tryParse(saldoController.text) ?? 0.0;

                    await _supabase.from('cuentas').insert({
                      'user_id': _supabase.auth.currentUser!.id,
                      'nombre': entidadSeleccionada, // Guarda el nombre elegido de la lista
                      'tipo': tipoSeleccionado,
                      'saldo_inicial': saldo,
                    });

                    if (context.mounted) Navigator.pop(context);
                    _cargarCuentas();
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

  Future<void> _cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuentas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _cerrarSesion),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: _cuentas.length,
                    itemBuilder: (context, index) {
                      final c = _cuentas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: _obtenerLogoImagen(c.nombre), // Muestra tu imagen local
                          title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Saldo inicial: S/ ${c.saldoInicial.toStringAsFixed(2)}\nTipo: ${c.tipo.toUpperCase()}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón de Editar Saldo
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editarSaldo(c),
                              ),
                              // Botón de Eliminar
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _eliminarCuenta(c),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: _mostrarDialogoNuevaCuenta,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Nueva Cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}