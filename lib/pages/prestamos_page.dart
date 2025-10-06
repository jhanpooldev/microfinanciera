import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrestamosPage extends StatefulWidget {
  const PrestamosPage({super.key});

  @override
  State<PrestamosPage> createState() => _PrestamosPageState();
}

class _PrestamosPageState extends State<PrestamosPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _interesController = TextEditingController(text: '10');
  final TextEditingController _plazoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  String? clienteSeleccionado;
  double totalPagar = 0.0;

  final CollectionReference prestamosRef =
      FirebaseFirestore.instance.collection('prestamos');
  final CollectionReference clientesRef =
      FirebaseFirestore.instance.collection('clientes');

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateTime.now().toString().split(' ')[0];
  }

  void _calcularTotal() {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final interes = double.tryParse(_interesController.text) ?? 0;
    final total = monto + (monto * interes / 100);
    setState(() {
      totalPagar = total;
    });
  }

  Future<void> _registrarPrestamo() async {
    if (_formKey.currentState!.validate()) {
      try {
        await prestamosRef.add({
          'cliente': clienteSeleccionado,
          'monto': double.parse(_montoController.text),
          'interes': double.parse(_interesController.text),
          'plazo_meses': int.parse(_plazoController.text),
          'fecha': _fechaController.text,
          'total_pagar': totalPagar,
          'estado': 'Activo',
          'fecha_registro': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préstamo registrado correctamente')),
        );

        _montoController.clear();
        _plazoController.clear();
        setState(() {
          totalPagar = 0.0;
          clienteSeleccionado = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _eliminarPrestamo(String id) async {
    await prestamosRef.doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Préstamo eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Préstamos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Selección del cliente
                  StreamBuilder<QuerySnapshot>(
                    stream: clientesRef.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final clientes = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: clienteSeleccionado,
                        decoration: const InputDecoration(labelText: 'Cliente'),
                        items: clientes.map((cliente) {
                          return DropdownMenuItem<String>(
                            value: cliente['nombre'],
                            child: Text(cliente['nombre']),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          setState(() {
                            clienteSeleccionado = valor;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Seleccione un cliente' : null,
                      );
                    },
                  ),
                  TextFormField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto del préstamo'),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese el monto' : null,
                    onChanged: (_) => _calcularTotal(),
                  ),
                  TextFormField(
                    controller: _interesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Interés (%)'),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese el interés' : null,
                    onChanged: (_) => _calcularTotal(),
                  ),
                  TextFormField(
                    controller: _plazoController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Plazo (en meses)'),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese el plazo' : null,
                  ),
                  TextFormField(
                    controller: _fechaController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Fecha'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total a pagar: S/ ${totalPagar.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _registrarPrestamo,
                    icon: const Icon(Icons.save),
                    label: const Text('Registrar Préstamo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lista de Préstamos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: prestamosRef
                    .orderBy('fecha_registro', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error al cargar los préstamos');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final prestamos = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: prestamos.length,
                    itemBuilder: (context, index) {
                      final prestamo = prestamos[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            prestamo['cliente'] ?? 'Sin cliente',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Monto: S/ ${prestamo['monto']} | Total: S/ ${prestamo['total_pagar']} | Plazo: ${prestamo['plazo_meses']} meses',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarPrestamo(prestamo.id),
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
