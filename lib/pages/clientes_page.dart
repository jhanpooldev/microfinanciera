import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  final CollectionReference clientesRef =
      FirebaseFirestore.instance.collection('clientes');

  Future<void> _registrarCliente() async {
    if (_formKey.currentState!.validate()) {
      try {
        await clientesRef.add({
          'nombre': _nombreController.text.trim(),
          'dni': _dniController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'direccion': _direccionController.text.trim(),
          'fecha_registro': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente registrado correctamente')),
        );

        _nombreController.clear();
        _dniController.clear();
        _telefonoController.clear();
        _direccionController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _eliminarCliente(String id) async {
    await clientesRef.doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese el nombre del cliente' : null,
                  ),
                  TextFormField(
                    controller: _dniController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'DNI'),
                    validator: (value) {
                      if (value!.isEmpty) return 'Ingrese el DNI';
                      if (value.length != 8) return 'El DNI debe tener 8 dígitos';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese un número de teléfono' : null,
                  ),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese una dirección' : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _registrarCliente,
                    icon: const Icon(Icons.save),
                    label: const Text('Registrar Cliente'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lista de Clientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: clientesRef.orderBy('fecha_registro', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error al cargar los datos');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final clientes = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      return Card(
                        child: ListTile(
                          title: Text(cliente['nombre']),
                          subtitle: Text(
                              'DNI: ${cliente['dni']} | Tel: ${cliente['telefono']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarCliente(cliente.id),
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
