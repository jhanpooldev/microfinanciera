import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeCajeroPage extends StatelessWidget {
  final _auth = AuthService();

  HomeCajeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Cajero'),
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
            icon: const Icon(Icons.payment),
            label: const Text('Registrar Pago'),
            onPressed: () => Navigator.pushNamed(context, '/pagos'),
          ),
        ],
      ),
    );
  }
}
