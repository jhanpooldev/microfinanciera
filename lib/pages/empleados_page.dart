import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _db = FirebaseFirestore.instance;

  String _email = '';
  String _password = '';
  String _rol = 'Analista';
  bool _loading = false;

  final List<String> rolesDisponibles = [
    'Analista',
    'Cajero',
    'Backoffice',
  ];

  Future<void> _crearEmpleado() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);

    try {
      await _authService.registrarEmpleado(
        _email,
        _password,
        _rol,
        creadorUid: 'VRPWf7b16rPACvfhosQzX86P9hI2',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empleado creado correctamente')),
      );
      _formKey.currentState!.reset();
      _cargarEmpleados();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear empleado: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> empleados = [];

  Future<void> _cargarEmpleados() async {
    final snapshot = await _db.collection('empleados').get();
    setState(() {
      empleados = snapshot.docs.map((d) => d.data()).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Empleados')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Registrar Nuevo Empleado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Correo inválido' : null,
                    onSaved: (v) => _email = v!,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                    onSaved: (v) => _password = v!,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _rol,
                    items: rolesDisponibles
                        .map((rol) => DropdownMenuItem(
                              value: rol,
                              child: Text(rol),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _rol = v!),
                    decoration: const InputDecoration(labelText: 'Rol del Empleado'),
                  ),
                  const SizedBox(height: 20),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _crearEmpleado,
                          child: const Text('Crear Empleado'),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              'Empleados Registrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ...empleados.map((e) => Card(
                  child: ListTile(
                    title: Text(e['correo']),
                    subtitle: Text('Rol: ${e['rol']}'),
                    leading: const Icon(Icons.person),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
