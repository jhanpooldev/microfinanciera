import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:microfinanciera/pages/gerente_dashboard_page.dart';
import '../services/auth_service.dart';

class GerenteHomePage extends StatefulWidget {
  const GerenteHomePage({super.key});

  @override
  State<GerenteHomePage> createState() => _GerenteHomePageState();
}

class _GerenteHomePageState extends State<GerenteHomePage> {
  final AuthService _authService = AuthService();

  /// 🔹 Cerrar sesión
  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  /// 🔹 Mostrar formulario para agregar empleado
  Future<void> _mostrarDialogoAgregarEmpleado() async {
    final _formKey = GlobalKey<FormState>();
    String correo = '';
    String password = '';
    String rol = 'Asesor';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('➕ Nuevo Empleado'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Correo inválido' : null,
                    onSaved: (v) => correo = v!.trim(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                    onSaved: (v) => password = v!.trim(),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: const [
                      DropdownMenuItem(value: 'Asesor', child: Text('Asesor')),
                      DropdownMenuItem(value: 'Backoffice', child: Text('Backoffice')),
                      DropdownMenuItem(value: 'Cajero', child: Text('Cajero')),
                    ],
                    onChanged: (v) => rol = v!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                _formKey.currentState!.save();

                try {
                  await _authService.registrarEmpleado(correo, password, rol);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Empleado "$rol" creado con éxito')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Eliminar empleado
  Future<void> _eliminarEmpleado(String id) async {
    try {
      await FirebaseFirestore.instance.collection('empleados').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empleado eliminado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  /// 🔹 Cuerpo principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Gerente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Ver Dashboards',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  GerenteDashboardPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('empleados')
            .orderBy('rol')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay empleados registrados.'));
          }

          final empleados = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: empleados.length,
            itemBuilder: (context, index) {
              final emp = empleados[index].data() as Map<String, dynamic>;
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text(
                      emp['rol'][0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(emp['correo'] ?? 'Sin correo'),
                  subtitle: Text('Rol: ${emp['rol']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _eliminarEmpleado(empleados[index].id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAgregarEmpleado,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Empleado'),
      ),
    );
  }
}
