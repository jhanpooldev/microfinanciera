import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:microfinanciera/pages/historial_clientes_page.dart';
import '../services/firestore_service.dart';

class ClientesPage extends StatefulWidget {
  @override
  _ClientesPageState createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final FirestoreService _firestoreService = FirestoreService();

  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  String? _clienteId; // null → nuevo cliente, no null → editar cliente

  /// Limpia los campos antes de registrar un nuevo cliente
  void _limpiarCampos() {
    _nombreCtrl.clear();
    _dniCtrl.clear();
    _telefonoCtrl.clear();
    _correoCtrl.clear();
    _direccionCtrl.clear();
    _clienteId = null;
  }

  /// Abre el formulario (crear / editar cliente)
  void _mostrarDialogoCliente({String? id, Map<String, dynamic>? data}) {
    if (data != null) {
      _clienteId = id;
      _nombreCtrl.text = data['nombre'] ?? '';
      _dniCtrl.text = data['dni'] ?? '';
      _telefonoCtrl.text = data['telefono'] ?? '';
      _correoCtrl.text = data['correo'] ?? '';
      _direccionCtrl.text = data['direccion'] ?? '';
    } else {
      _limpiarCampos();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_clienteId == null ? 'Registrar Cliente' : 'Editar Cliente'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Ingrese el nombre del cliente'
                      : null,
                ),
                TextFormField(
                  controller: _dniCtrl,
                  decoration: const InputDecoration(labelText: 'DNI'),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese el DNI';
                    if (v.length != 8) return 'El DNI debe tener 8 dígitos';
                    if (int.tryParse(v) == null) return 'El DNI solo acepta números';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese el teléfono';
                    if (v.length != 9) return 'El teléfono debe tener 9 dígitos';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _correoCtrl,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese el correo';
                    final emailReg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailReg.hasMatch(v)) return 'Correo inválido';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Ingrese la dirección'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text(_clienteId == null ? 'Guardar' : 'Actualizar'),
            onPressed: _guardarCliente,
          ),
        ],
      ),
    );
  }

  /// Guarda o actualiza cliente
  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    final clienteData = {
      'nombre': _nombreCtrl.text.trim(),
      'dni': _dniCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'correo': _correoCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
    };

    try {
      if (_clienteId == null) {
        await _firestoreService.agregarCliente(clienteData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente registrado correctamente')),
        );
      } else {
        await _firestoreService.actualizarCliente(_clienteId!, clienteData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente actualizado correctamente')),
        );
      }

      Navigator.pop(context);
      _limpiarCampos();
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  /// Confirmar eliminación
  void _confirmarEliminar(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content:
            const Text('¿Seguro que deseas eliminar este cliente permanentemente?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firestoreService.eliminarCliente(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cliente eliminado correctamente')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Clientes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.obtenerClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final clientes = snapshot.data?.docs ?? [];
          if (clientes.isEmpty) {
            return const Center(child: Text('No hay clientes registrados.'));
          }

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index].data() as Map<String, dynamic>;
              final id = clientes[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    cliente['nombre'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DNI: ${cliente['dni'] ?? ''}'),
                      Text('Correo: ${cliente['correo'] ?? ''}'),
                      Text('Teléfono: ${cliente['telefono'] ?? ''}'),
                      Text('Dirección: ${cliente['direccion'] ?? ''}'),
                      Text('Estado: ${cliente['estado'] ?? 'activo'}'),
                      if (cliente['fechaRegistro'] != null)
                        Text(
                          'Registrado: ${DateTime.parse(cliente['fechaRegistro']).toLocal().toString().split(' ')[0]}',
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistorialClientePage(
                          clienteId: cliente['id'],
                          clienteNombre: cliente['nombre'],
                        ),
                       ),
                      );
                     },

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') {
                        _mostrarDialogoCliente(id: id, data: cliente);
                      } else if (value == 'eliminar') {
                        _confirmarEliminar(id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoCliente(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
