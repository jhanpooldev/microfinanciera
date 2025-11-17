import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SetupGerentePage extends StatefulWidget {
  const SetupGerentePage({super.key});

  @override
  State<SetupGerentePage> createState() => _SetupGerentePageState();
}

class _SetupGerentePageState extends State<SetupGerentePage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String _email = '';
  String _password = '';
  bool _loading = false;

  Future<void> _crearGerente() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    try {
      // 🔹 Verificar si ya existe un gerente
      final snapshot = await FirebaseFirestore.instance
          .collection('empleados')
          .where('rol', isEqualTo: 'Gerente')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Ya existe un gerente registrado')),
        );
        setState(() => _loading = false);
        return;
      }

      // 🔹 Crear gerente con rol
      final user = await _authService.registrarEmpleado(
        _email.trim(),
        _password.trim(),
        'Gerente',
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Gerente creado correctamente')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear gerente: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración Inicial - Gerente')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Registrar Gerente del Sistema',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Correo del Gerente'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese correo';
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
                onSaved: (v) => _email = v!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                onSaved: (v) => _password = v!,
              ),
              const SizedBox(height: 25),
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _crearGerente,
                        child: const Text('Crear Gerente'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
