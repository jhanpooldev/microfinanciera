import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PagosPage extends StatefulWidget {
  const PagosPage({super.key});

  @override
  State<PagosPage> createState() => _PagosPageState();
}

class _PagosPageState extends State<PagosPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idPrestamoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _fechaPagoController = TextEditingController();

  final CollectionReference prestamosRef =
      FirebaseFirestore.instance.collection('prestamos');
  final CollectionReference pagosRef =
      FirebaseFirestore.instance.collection('pagos');

  @override
  void initState() {
    super.initState();
    _fechaPagoController.text = DateTime.now().toString().split(' ')[0];
  }

  Future<void> _registrarPago() async {
    if (_formKey.currentState!.validate()) {
      try {
        final idPrestamo = _idPrestamoController.text.trim();
        final montoPago = double.parse(_montoController.text);

        // Buscar el préstamo
        final prestamoSnap = await prestamosRef.doc(idPrestamo).get();

        if (!prestamoSnap.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El préstamo no existe')),
          );
          return;
        }

        final prestamo = prestamoSnap.data() as Map<String, dynamic>;
        final saldoPendiente = prestamo['saldo'] ?? prestamo['monto'];

        if (montoPago > saldoPendiente) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El monto supera el saldo pendiente')),
          );
          return;
        }

        // Registrar pago
        await pagosRef.add({
          'id_prestamo': idPrestamo,
          'monto_pago': montoPago,
          'fecha_pago': _fechaPagoController.text,
          'fecha_registro': Timestamp.now(),
        });

        // Actualizar saldo del préstamo
        final nuevoSaldo = saldoPendiente - montoPago;
        await prestamosRef.doc(idPrestamo).update({
          'saldo': nuevoSaldo,
          'estado': nuevoSaldo <= 0 ? 'Pagado' : 'Activo',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado correctamente')),
        );

        _idPrestamoController.clear();
        _montoController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _eliminarPago(String id) async {
    await pagosRef.doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pago eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos de Préstamos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _idPrestamoController,
                    decoration: const InputDecoration(
                      labelText: 'ID del préstamo',
                      hintText: 'Ejemplo: abc123xyz...',
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese el ID del préstamo' : null,
                  ),
                  TextFormField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto del pago (S/)'),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese el monto' : null,
                  ),
                  TextFormField(
                    controller: _fechaPagoController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Fecha del pago'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _registrarPago,
                    icon: const Icon(Icons.payment),
                    label: const Text('Registrar Pago'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Historial de Pagos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: pagosRef.orderBy('fecha_registro', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error al cargar los pagos');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pagos = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: pagos.length,
                    itemBuilder: (context, index) {
                      final pago = pagos[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long, color: Colors.teal),
                          title: Text(
                            'Pago S/ ${pago['monto_pago']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('ID Préstamo: ${pago['id_prestamo']} | Fecha: ${pago['fecha_pago']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarPago(pago.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
