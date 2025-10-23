import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';

class EmpleadosPage extends StatefulWidget {
  final String userRole; // 'Administrador', 'Analista', etc.
  const EmpleadosPage({super.key, this.userRole = 'Invitado'});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _sueldoController = TextEditingController();
  String _rolSeleccionado = 'Analista';
  final List<String> roles = ['Administrador', 'Analista', 'Cajero', 'Invitado'];
  String? _empleadoId; // para edición
  final _formKey = GlobalKey<FormState>();

  void _abrirFormulario({Map<String, dynamic>? data}) {
    if (data != null) {
      _empleadoId = data['id'];
      _nombreController.text = data['nombre'];
      _correoController.text = data['correo'];
      _sueldoController.text = data['sueldo'].toString();
      _rolSeleccionado = data['cargo'];
    } else {
      _empleadoId = null;
      _nombreController.clear();
      _correoController.clear();
      _sueldoController.clear();
      _rolSeleccionado = 'Analista';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_empleadoId == null ? 'Nuevo empleado' : 'Editar empleado'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
                TextFormField(
                  controller: _correoController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _sueldoController,
                  decoration: const InputDecoration(labelText: 'Sueldo'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    final val = double.tryParse(v);
                    if (val == null || val <= 0) return 'Sueldo inválido';
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _rolSeleccionado,
                  decoration: const InputDecoration(labelText: 'Cargo'),
                  items: roles.map((rol) {
                    return DropdownMenuItem(value: rol, child: Text(rol));
                  }).toList(),
                  onChanged: (v) => setState(() => _rolSeleccionado = v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _guardarEmpleado,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarEmpleado() async {
    if (!_formKey.currentState!.validate()) return;

    final empleado = {
      'nombre': _nombreController.text.trim(),
      'correo': _correoController.text.trim(),
      'cargo': _rolSeleccionado,
      'sueldo': double.parse(_sueldoController.text.trim()),
    };

    try {
      if (_empleadoId == null) {
        if (widget.userRole != 'Administrador') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solo un administrador puede crear empleados')),
          );
          return;
        }
        await _firestoreService.agregarEmpleado(empleado);
      } else {
        await _firestoreService.actualizarEmpleado(_empleadoId!, empleado);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _eliminarEmpleado(String id) async {
    if (widget.userRole != 'Administrador') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo un administrador puede eliminar empleados')),
      );
      return;
    }

    await _firestoreService.eliminarEmpleado(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de empleados')),
      floatingActionButton: widget.userRole == 'Administrador'
          ? FloatingActionButton(
              onPressed: () => _abrirFormulario(),
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.obtenerEmpleados(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar empleados'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final empleados = snapshot.data!.docs;

          if (empleados.isEmpty) {
            return const Center(child: Text('No hay empleados registrados'));
          }

          return ListView.builder(
            itemCount: empleados.length,
            itemBuilder: (context, i) {
              final data = empleados[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['nombre'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Correo: ${data['correo'] ?? ''}'),
                      Text('Cargo: ${data['cargo'] ?? ''}'),
                      Text('Sueldo: S/${data['sueldo'] ?? 0}'),
                    ],
                  ),
                  trailing: widget.userRole == 'Administrador'
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar') _abrirFormulario(data: data);
                            if (value == 'eliminar') _eliminarEmpleado(data['id']);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'editar', child: Text('Editar')),
                            PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

}
