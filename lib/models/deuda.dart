// Archivo: lib/models/deuda.dart
class Deuda {
  final String id;
  final String tipo; // 'yo_debo' o 'me_deben'
  final String persona;
  final double monto;
  final bool pagada;

  Deuda({
    required this.id,
    required this.tipo,
    required this.persona,
    required this.monto,
    required this.pagada,
  });

  factory Deuda.fromJson(Map<String, dynamic> json) {
    return Deuda(
      id: json['id'],
      tipo: json['tipo'],
      persona: json['persona'],
      monto: (json['monto'] as num).toDouble(),
      pagada: json['pagada'] ?? false,
    );
  }
}