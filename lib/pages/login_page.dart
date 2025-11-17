import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 🔹 Iniciar sesión con Firebase
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        final rol = await _authService.obtenerRol(_emailController.text.trim());
        if (!mounted) return;
        
        if (rol == 'Gerente') {
          Navigator.pushReplacementNamed(context, '/gerente_home');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensaje = 'Error desconocido';
      if (e.code == 'user-not-found') mensaje = 'Usuario no encontrado';
      if (e.code == 'wrong-password') mensaje = 'Contraseña incorrecta';
      if (e.code == 'invalid-email') mensaje = 'Correo no válido';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 90, color: Colors.teal),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Ingresa tu correo';
                    } else if (!v.contains('@')) {
                      return 'Correo inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa tu contraseña' : null,
                ),
                const SizedBox(height: 30),
                _loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('Iniciar sesión'),
                        ),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: const Text('¿No tienes cuenta? Regístrate aquí'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}