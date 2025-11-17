import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeAsesorPage extends StatelessWidget {
  final _auth = AuthService();

  HomeAsesorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Asesor'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Registrar Cliente'),
            onPressed: () => Navigator.pushNamed(context, '/clientes'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.request_page),
            label: const Text('Registrar Crédito'),
            onPressed: () => Navigator.pushNamed(context, '/creditos'),
          ),
        ],
      ),
    );
  }
}
