import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HistorialClientePage extends StatelessWidget {
  final String clienteId;
  final String clienteNombre;

  const HistorialClientePage({
    super.key,
    required this.clienteId,
    required this.clienteNombre,
  });

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');

    return Scaffold(
      appBar: AppBar(title: Text('Historial de $clienteNombre')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('prestamos')
            .where('clienteId', isEqualTo: clienteId)
            .snapshots(),
        builder: (context, snapshotPrestamos) {
          if (!snapshotPrestamos.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final prestamos = snapshotPrestamos.data!.docs;

          if (prestamos.isEmpty) {
            return const Center(child: Text('Este cliente no tiene préstamos.'));
          }

          return ListView.builder(
            itemCount: prestamos.length,
            itemBuilder: (context, index) {
              final prestamo = prestamos[index].data() as Map<String, dynamic>;
              final prestamoId = prestamos[index].id;

              return Card(
                margin: const EdgeInsets.all(8),
                elevation: 3,
                child: ExpansionTile(
                  leading: Icon(
                    prestamo['estado'] == 'Pagado'
                        ? Icons.check_circle
                        : Icons.pending_actions,
                    color: prestamo['estado'] == 'Pagado'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(
                    'Préstamo: ${formato.format(prestamo['monto'] ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(prestamo['fecha']))}\n'
                    'Estado: ${prestamo['estado']}',
                  ),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('pagos')
                          .where('prestamoId', isEqualTo: prestamoId)
                          .snapshots(),
                      builder: (context, snapshotPagos) {
                        if (!snapshotPagos.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final pagos = snapshotPagos.data!.docs;

                        double totalPagado = 0.0;
                        for (var doc in pagos) {
                          totalPagado += (doc['monto'] ?? 0).toDouble();
                        }

                        final totalPagar = (prestamo['totalPagar'] ?? 0).toDouble();
                        final saldoRestante = (totalPagar - totalPagado).clamp(0, totalPagar);

                        final double porcentajePagado =
                            totalPagar == 0 ? 0 : (totalPagado / totalPagar) * 100;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Resumen de pagos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text('${porcentajePagado.toStringAsFixed(1)}% pagado'),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 160,
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 45,
                                  sections: [
                                    PieChartSectionData(
                                      value: totalPagado,
                                      color: Colors.teal,
                                      title: 'Pagado',
                                      radius: 55,
                                      titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      value: saldoRestante,
                                      color: Colors.redAccent,
                                      title: 'Pendiente',
                                      radius: 55,
                                      titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total a pagar: ${formato.format(totalPagar)}'),
                                  Text('Pagado: ${formato.format(totalPagado)}'),
                                  Text('Saldo restante: ${formato.format(saldoRestante)}'),
                                ],
                              ),
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: const Text(
                                'Historial de pagos:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                            ...pagos.map((p) {
                              final data = p.data() as Map<String, dynamic>;
                              return ListTile(
                                leading: const Icon(Icons.payments, color: Colors.green),
                                title: Text(
                                    'Monto: ${formato.format(data['monto'] ?? 0)}'),
                                subtitle: Text(
                                  'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(data['fecha']))}',
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
