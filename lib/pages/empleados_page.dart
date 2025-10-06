import 'package:flutter/material.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  final List<Map<String, String>> empleados = [];

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController cargoCtrl = TextEditingController();

  void agregarEmpleado() {
    if (nombreCtrl.text.isNotEmpty && cargoCtrl.text.isNotEmpty) {
      setState(() {
        empleados.add({
          'nombre': nombreCtrl.text,
          'cargo': cargoCtrl.text,
        });
      });
      nombreCtrl.clear();
      cargoCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Empleados")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogo(),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: empleados.length,
        itemBuilder: (context, index) {
          final empleado = empleados[index];
          return ListTile(
            leading: const Icon(Icons.badge),
            title: Text(empleado['nombre'] ?? ''),
            subtitle: Text("Cargo: ${empleado['cargo']}"),
          );
        },
      ),
    );
  }

  void _mostrarDialogo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Empleado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: cargoCtrl, decoration: const InputDecoration(labelText: "Cargo")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () { agregarEmpleado(); Navigator.pop(context); }, child: const Text("Guardar")),
        ],
      ),
    );
  }
}
