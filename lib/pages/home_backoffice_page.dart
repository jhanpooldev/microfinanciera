import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeBackOfficePage extends StatelessWidget {
  final _auth = AuthService();

  HomeBackOfficePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Back Office'),
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
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Aprobar Créditos'),
            onPressed: () => Navigator.pushNamed(context, '/aprobaciones'),
          ),
        ],
      ),
    );
  }
}
