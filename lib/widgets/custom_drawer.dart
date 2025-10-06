import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Text(
              'Microfinanciera',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Clientes'),
            onTap: () => Navigator.pushNamed(context, '/clientes'),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Créditos'),
            onTap: () => Navigator.pushNamed(context, '/creditos'),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Empleados'),
            onTap: () => Navigator.pushNamed(context, '/empleados'),
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Pagos'),
            onTap: () => Navigator.pushNamed(context, '/pagos'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
