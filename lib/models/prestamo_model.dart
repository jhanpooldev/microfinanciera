class Prestamo {
  final String id;
  final String clienteId;
  final double monto;
  final double saldo;
  final DateTime fecha;

  Prestamo({
    required this.id,
    required this.clienteId,
    required this.monto,
    required this.saldo,
    required this.fecha,
  });
}
