class Prestamo {
  final String id;
  final String cliente;
  final double monto;
  final double tasaInteres;
  final int plazoMeses;
  final String estado;
  final DateTime fechaRegistro;
  final String motivoRechazo;

  Prestamo({
    required this.id,
    required this.cliente,
    required this.monto,
    required this.tasaInteres,
    required this.plazoMeses,
    required this.estado,
    required this.fechaRegistro,
    required this.motivoRechazo
  });

  // Convertir a mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'cliente': cliente,
      'monto': monto,
      'tasaInteres': tasaInteres,
      'plazoMeses': plazoMeses,
      'estado': estado,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'motivoRechazo': motivoRechazo,
    };
  }

  // Crear objeto desde Firestore
  factory Prestamo.fromMap(Map<String, dynamic> map, String id) {
    return Prestamo(
      id: id,
      cliente: map['cliente'] ?? '',
      monto: (map['monto'] ?? 0).toDouble(),
      tasaInteres: (map['tasaInteres'] ?? 0).toDouble(),
      plazoMeses: (map['plazoMeses'] ?? 0).toInt(),
      estado: map['estado'] ?? 'Pendiente', // 👈 CAMBIADO (antes 'Activo')
      fechaRegistro: DateTime.tryParse(map['fechaRegistro'] ?? '') ?? DateTime.now(),
      motivoRechazo: map['motivoRechazo'],

    );
  }
}
