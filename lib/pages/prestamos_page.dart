import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'historial_pagos_page.dart'; // 👈 nuevo import

class PrestamosPage extends StatefulWidget {
  @override
  _PrestamosPageState createState() => _PrestamosPageState();
}

class _PrestamosPageState extends State<PrestamosPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  // controladores
  final _montoCtrl = TextEditingController();
  final _tasaCtrl = TextEditingController();
  final _plazoCtrl = TextEditingController();
  String? _clienteSeleccionado;
  String? _prestamoId;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _tasaCtrl.dispose();
    _plazoCtrl.dispose();
    super.dispose();
  }

  void _limpiarCampos() {
    _montoCtrl.clear();
    _tasaCtrl.clear();
    _plazoCtrl.clear();
    _clienteSeleccionado = null;
    _prestamoId = null;
  }

  // ============================
  //  FORMULARIO DE PRÉSTAMO
  // ============================
  void _mostrarDialogoPrestamo({String? id, Map<String, dynamic>? data}) {
    if (data != null) {
      _prestamoId = id;
      _clienteSeleccionado = data['clienteId'];
      _montoCtrl.text = data['monto'].toString();
      _tasaCtrl.text = data['tasa'].toString();
      _plazoCtrl.text = data['plazo'].toString();
    } else {
      _limpiarCampos();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_prestamoId == null ? 'Registrar Préstamo' : 'Editar Préstamo'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final clientes = snapshot.data!.docs;

                    if (clientes.isEmpty) {
                      return const Text('No hay clientes registrados.');
                    }

                    return DropdownButtonFormField<String>(
                      value: _clienteSeleccionado,
                      hint: const Text('Seleccionar Cliente'),
                      items: clientes.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['nombre'] ?? 'Sin nombre'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _clienteSeleccionado = v),
                      validator: (v) => v == null ? 'Seleccione un cliente válido' : null,
                    );
                  },
                ),
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto (S/.)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese el monto';
                    final monto = double.tryParse(v);
                    if (monto == null || monto <= 0) return 'El monto debe ser mayor que 0';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _tasaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tasa de interés (%)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese la tasa de interés';
                    final tasa = double.tryParse(v);
                    if (tasa == null || tasa <= 0) return 'La tasa debe ser mayor que 0';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _plazoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Plazo (meses)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingrese el plazo';
                    final plazo = int.tryParse(v);
                    if (plazo == null || plazo <= 0) return 'El plazo debe ser mayor que 0';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: _guardarPrestamo,
            child: Text(_prestamoId == null ? 'Registrar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  // ============================
  //  GUARDAR O EDITAR PRÉSTAMO
  // ============================
  Future<void> _guardarPrestamo() async {
    if (!_formKey.currentState!.validate()) return;

    final clienteId = _clienteSeleccionado!;
    final monto = double.parse(_montoCtrl.text.trim());
    final tasa = double.parse(_tasaCtrl.text.trim());
    final plazo = int.parse(_plazoCtrl.text.trim());

    final interes = monto * (tasa / 100);
    final totalPagar = monto + interes;

    try {
      // Verificar préstamo activo duplicado
      final prestamosCliente = await FirebaseFirestore.instance
          .collection('prestamos')
          .where('clienteId', isEqualTo: clienteId)
          .where('estado', isEqualTo: 'Activo')
          .get();

      if (_prestamoId == null && prestamosCliente.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El cliente ya tiene un préstamo activo.')),
        );
        return;
      }

      // 🔹 Obtener nombre del cliente seleccionado
      final clienteDoc = await FirebaseFirestore.instance.collection('clientes').doc(clienteId).get();
      final clienteData = clienteDoc.data() as Map<String, dynamic>?;

      final prestamoData = {
        'clienteId': clienteId,
        'clienteNombre': clienteData?['nombre'] ?? 'Desconocido',
        'monto': monto,
        'tasa': tasa,
        'plazo': plazo,
        'interesTotal': interes,
        'totalPagar': totalPagar,
        'saldoRestante': totalPagar,
        'fecha': DateTime.now().toIso8601String(),
        'estado': 'Activo',
      };

      if (_prestamoId == null) {
        await _firestoreService.agregarPrestamo(prestamoData);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Préstamo registrado correctamente')));
      } else {
        await _firestoreService.actualizarPrestamo(_prestamoId!, prestamoData);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Préstamo actualizado correctamente')));
      }

      Navigator.pop(context);
      _limpiarCampos();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  // ============================
  //  ELIMINAR PRÉSTAMO
  // ============================
  void _confirmarEliminar(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Préstamo'),
        content: const Text('¿Seguro que deseas eliminar este préstamo permanentemente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firestoreService.eliminarPrestamo(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Préstamo eliminado correctamente')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ============================
  //  UI PRINCIPAL
  // ============================
  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Préstamos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.obtenerPrestamos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final prestamos = snapshot.data?.docs ?? [];

          if (prestamos.isEmpty)
            return const Center(child: Text('No hay préstamos registrados.'));

          return ListView.builder(
            itemCount: prestamos.length,
            itemBuilder: (context, i) {
              final prestamo = prestamos[i].data() as Map<String, dynamic>;
              final id = prestamos[i].id;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(
                    prestamo['estado'] == 'Pagado'
                        ? Icons.check_circle
                        : Icons.pending,
                    color: prestamo['estado'] == 'Pagado'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text('Cliente: ${prestamo['clienteNombre'] ?? 'Desconocido'}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monto: ${formato.format(prestamo['monto'] ?? 0)}'),
                      Text('Interés: ${formato.format(prestamo['interesTotal'] ?? 0)}'),
                      Text('Total a pagar: ${formato.format(prestamo['totalPagar'] ?? 0)}'),
                      Text('Saldo restante: ${formato.format(prestamo['saldoRestante'] ?? 0)}'),
                      Text('Tasa: ${prestamo['tasa']}% | Plazo: ${prestamo['plazo']} meses'),
                      Text('Estado: ${prestamo['estado'] ?? 'Activo'}'),
                      Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(prestamo['fecha']))}',
                      ),
                    ],
                  ),
                  onTap: () {
                    // 👇 Nuevo: abrir historial de pagos
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistorialPagosPage(
                          prestamoId: id,
                          clienteNombre: prestamo['clienteNombre'] ?? 'Desconocido',
                          totalPagar: (prestamo['totalPagar'] ?? 0).toDouble(),
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'editar') {
                        _mostrarDialogoPrestamo(id: id, data: prestamo);
                      } else if (v == 'eliminar') {
                        _confirmarEliminar(id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoPrestamo(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
