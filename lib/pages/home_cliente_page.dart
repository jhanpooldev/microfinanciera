import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'solicitar_prestamo_page.dart';

class HomeClientePage extends StatelessWidget {
  final _auth = AuthService();

  HomeClientePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil de Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${user?.email ?? 'Cliente'}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_money),
              label: const Text('Solicitar un nuevo préstamo'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SolicitarPrestamoPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mis Solicitudes de Préstamo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Aquí iría un StreamBuilder para mostrar sus préstamos pendientes/aprobados
          ],
        ),
      ),
    );
  }
}