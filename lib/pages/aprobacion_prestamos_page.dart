import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AprobacionPrestamosPage extends StatelessWidget {
  final _db = FirebaseFirestore.instance;

  AprobacionPrestamosPage({super.key});

  // Lógica para aprobar (Mantiene igual)
  Future<void> _aprobarPrestamo(BuildContext context, String prestamoId, double monto) async {
    final double tasaInteres = 15.0; 
    final interes = monto * (tasaInteres / 100);
    final totalPagar = monto + interes;

    await _db.collection('prestamos').doc(prestamoId).update({
      'estado': 'Aprobado',
      'tasaInteres': tasaInteres,
      'totalPagar': totalPagar,
      'saldoRestante': totalPagar,
      'fechaAprobacion': DateTime.now().toIso8601String(),
    });
    
    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Préstamo Aprobado')));
    }
  }

  // Lógica para rechazar (Mantiene igual)
  Future<void> _rechazarPrestamo(BuildContext context, String prestamoId) async {
    await _db.collection('prestamos').doc(prestamoId).update({
      'estado': 'Rechazado',
      'motivoRechazo': "Requisitos insuficientes",
    });
     if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Préstamo Rechazado')));
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes Pendientes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('prestamos')
            .where('estado', isEqualTo: 'Pendiente')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final solicitudes = snapshot.data!.docs;

          if (solicitudes.isEmpty) {
            return const Center(child: Text('No hay solicitudes pendientes.'));
          }

          return ListView.builder(
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final solicitud = solicitudes[index].data() as Map<String, dynamic>;
              final prestamoId = solicitudes[index].id;
              
              final clienteEmail = solicitud['clienteEmail'] ?? 'Sin email';
              final monto = (solicitud['monto'] ?? 0).toDouble();
              final plazo = (solicitud['plazoMeses'] ?? 0);
              final dniNumero = solicitud['dniNumero'] ?? 'No registrado'; // 👈 Leemos el DNI texto
              final score = solicitud['scoreAlMomento'] ?? 0;

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SOLICITUD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(solicitud['fechaRegistro']))),
                        ],
                      ),
                      const Divider(),
                      
                      // Datos principales
                      Text('Cliente: $clienteEmail', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 5),
                      Text('DNI: $dniNumero', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // 👈 Mostramos DNI
                      const SizedBox(height: 5),
                      Text('Score Crediticio: $score', style: TextStyle(color: score >= 500 ? Colors.green : Colors.red)),
                      
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Monto: S/ ${monto.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
                          Text('Plazo: $plazo meses'),
                        ],
                      ),

                      const SizedBox(height: 20),
                      
                      // Botones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                            onPressed: () => _rechazarPrestamo(context, prestamoId),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Aprobar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () => _aprobarPrestamo(context, prestamoId, monto),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
