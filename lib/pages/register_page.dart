import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _db = FirebaseFirestore.instance; // Para guardar en la colección 'clientes'

  // Controladores
  final _nombreCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // 1. Crear Usuario y Autenticación (Guarda en 'empleados' con rol Cliente)
      final user = await _authService.registrarEmpleado(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
        'Cliente', 
      );

      if (user != null) {
        // 2. 🟢 CLAVE: Guardar también en la colección 'clientes'
        // Usamos el user.uid para que el ID sea el mismo en ambas colecciones
        await _db.collection('clientes').doc(user.uid).set({
          'id': user.uid,
          'nombre': _nombreCtrl.text.trim(),
          'dni': _dniCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim(),
          'correo': _emailCtrl.text.trim(),
          'direccion': _direccionCtrl.text.trim(),
          'estado': 'activo',
          'fechaRegistro': DateTime.now().toIso8601String(),
          // El score se guarda en 'empleados' según tu AuthService, 
          // pero podrías replicarlo aquí si lo necesitas visualizar fácil.
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro exitoso. Bienvenido.')),
          );
          // Redirigir al home de cliente
          Navigator.pushReplacementNamed(context, '/home_cliente');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Cliente')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_pin, size: 80, color: Colors.teal),
                const SizedBox(height: 20),
                const Text('Datos Personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 10),

                // DNI y Teléfono en la misma fila
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dniCtrl,
                        decoration: const InputDecoration(labelText: 'DNI', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        validator: (v) => v!.length != 8 ? '8 dígitos' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoCtrl,
                        decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                
                // Dirección
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                ),
                
                const SizedBox(height: 20),
                const Text('Datos de Cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains('@') ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 10),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)),
                  validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),

                const SizedBox(height: 30),

                _loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('REGISTRARME', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}