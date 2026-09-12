// Archivo: lib/models/cuenta.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Cuenta {
  final String? id;
  final String nombre;
  final String tipo;
  final double saldoInicial;

  Cuenta({
    this.id, 
    required this.nombre, 
    required this.tipo, 
    this.saldoInicial = 0.0
  });

  factory Cuenta.fromJson(Map<String, dynamic> json) {
    return Cuenta(
      id: json['id'],
      nombre: json['nombre'],
      tipo: json['tipo'],
      saldoInicial: (json['saldo_inicial'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': Supabase.instance.client.auth.currentUser!.id,
      'nombre': nombre,
      'tipo': tipo,
      'saldo_inicial': saldoInicial,
    };
  }
}