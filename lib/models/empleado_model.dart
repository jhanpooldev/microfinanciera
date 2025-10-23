class Empleado {
  final String id;
  final String nombre;
  final String correo;
  final String cargo; // Ejemplo: Administrador, Analista, Cajero, Invitado
  final double sueldo;
  final DateTime fechaRegistro;

  Empleado({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.cargo,
    required this.sueldo,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'cargo': cargo,
      'sueldo': sueldo,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }

  factory Empleado.fromMap(Map<String, dynamic> map, String id) {
    return Empleado(
      id: id,
      nombre: map['nombre'] ?? '',
      correo: map['correo'] ?? '',
      cargo: map['cargo'] ?? '',
      sueldo: (map['sueldo'] ?? 0).toDouble(),
      fechaRegistro:
          DateTime.tryParse(map['fechaRegistro'] ?? '') ?? DateTime.now(),
    );
  }
}
