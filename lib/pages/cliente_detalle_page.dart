import 'package:flutter/material.dart';
import '../models/cliente_model.dart';

class ClienteDetallePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Cliente cliente = ModalRoute.of(context)!.settings.arguments as Cliente;
    return Scaffold(
      appBar: AppBar(title: Text(cliente.nombre)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correo: ${cliente.correo}'),
            SizedBox(height: 8),
            Text('Teléfono: ${cliente.telefono}'),
          ],
        ),
      ),
    );
  }
}
