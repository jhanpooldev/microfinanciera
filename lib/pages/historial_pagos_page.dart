import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialPagosPage extends StatelessWidget {
  final String prestamoId;
  final String clienteNombre;
  final double totalPagar;

  const HistorialPagosPage({
    super.key,
    required this.prestamoId,
    required this.clienteNombre,
    required this.totalPagar,
  });

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');

    return Scaffold(
      appBar: AppBar(title: Text('Historial de Pagos - $clienteNombre')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pagos')
            .where('prestamoId', isEqualTo: prestamoId)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pagos = snapshot.data?.docs ?? [];

          if (pagos.isEmpty) {
            return const Center(
              child: Text('No hay pagos registrados para este préstamo.'),
            );
          }

          double totalPagado = pagos.fold(
              0.0, (sum, doc) => sum + (doc['monto'] as num).toDouble());
          double saldoRestante = totalPagar - totalPagado;

          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: $clienteNombre',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Total del préstamo: ${formato.format(totalPagar)}'),
                Text('Total pagado: ${formato.format(totalPagado)}'),
                Text('Saldo restante: ${formato.format(saldoRestante)}'),
                const Divider(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: pagos.length,
                    itemBuilder: (context, i) {
                      final pago = pagos[i].data() as Map<String, dynamic>;
                      final fecha = DateTime.tryParse(pago['fecha'] ?? '');

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.attach_money_rounded,
                              color: Colors.green),
                          title: Text(
                              'Monto pagado: ${formato.format(pago['monto'] ?? 0)}'),
                          subtitle: Text(
                            'Saldo restante: ${formato.format(pago['saldoRestante'] ?? 0)}\n'
                            'Fecha: ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'Sin fecha'}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
