class Pago {
  final String id;
  final String prestamoId;
  final double monto;
  final DateTime fecha;

  Pago({
    required this.id,
    required this.prestamoId,
    required this.monto,
    required this.fecha,
  });
}
