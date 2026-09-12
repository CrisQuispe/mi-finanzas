// Archivo: lib/models/movimiento.dart
class Movimiento {
  final String id;
  final String cuentaId;
  final String cuentaNombre; 
  final String tipo;
  final String categoria;
  final String? descripcion;
  final double monto;
  final DateTime fecha;

  Movimiento({
    required this.id,
    required this.cuentaId,
    required this.cuentaNombre,
    required this.tipo,
    required this.categoria,
    this.descripcion,
    required this.monto,
    required this.fecha,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      id: json['id'],
      cuentaId: json['cuenta_id'],
      cuentaNombre: json['cuentas'] != null ? json['cuentas']['nombre'] : 'Desconocida',
      tipo: json['tipo'],
      categoria: json['categoria'],
      descripcion: json['descripcion'],
      monto: (json['monto'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] ?? json['created_at']),
    );
  }
}