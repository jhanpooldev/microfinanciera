import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'aprobacion_prestamos_page.dart'; 

class HomeAsesorPage extends StatelessWidget {
  final _auth = AuthService();

  HomeAsesorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Analista'), // 👈 CAMBIO: Ahora dice Analista
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
            icon: const Icon(Icons.people),
            label: const Text('Ver Clientes'),
            onPressed: () => Navigator.pushNamed(context, '/clientes'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.verified_user),
            label: const Text('Aprobar Solicitudes Pendientes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade100,
              foregroundColor: Colors.orange.shade900,
              padding: const EdgeInsets.all(15),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AprobacionPrestamosPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}