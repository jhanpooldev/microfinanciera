class Cliente {
  final String id;
  final String nombre;
  final String dni;
  final String telefono;
  final String correo;
  final String direccion;
  final DateTime fechaRegistro;
  final String? dniFotoUrl;
  final int? scoreCrediticio;

   Cliente({
    required this.id,
    required this.nombre,
    required this.dni,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.fechaRegistro,
    this.dniFotoUrl, 
    this.scoreCrediticio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'dni': dni,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'dniFotoUrl': dniFotoUrl, 
      'scoreCrediticio': scoreCrediticio, 
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map, String id) {
    return Cliente(
      id: id,
      nombre: map['nombre'] ?? '',
      dni: map['dni'] ?? '',
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      direccion: map['direccion'] ?? '',
      fechaRegistro:
          DateTime.tryParse(map['fechaRegistro'] ?? '') ?? DateTime.now(),
      dniFotoUrl: map['dniFotoUrl'],
      scoreCrediticio: map['scoreCrediticio'],
    );
  }
}
