import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class PagosPage extends StatefulWidget {
  const PagosPage({super.key});

  @override
  State<PagosPage> createState() => _PagosPageState();
}

class _PagosPageState extends State<PagosPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  String? _prestamoSeleccionado;
  String? _clienteNombre;
  double _montoPago = 0.0;
  double _saldoRestante = 0.0;
  String? _pagoId;

  // ==========================
  // Mostrar diálogo de pago
  // ==========================
  void _mostrarDialogoPago({Map<String, dynamic>? pagoExistente}) {
    if (pagoExistente != null) {
      _pagoId = pagoExistente['id'];
      _prestamoSeleccionado = pagoExistente['prestamoId'];
      _clienteNombre = pagoExistente['clienteNombre'];
      _montoPago = pagoExistente['monto'];
      _saldoRestante = pagoExistente['saldoRestante'];
    } else {
      _pagoId = null;
      _prestamoSeleccionado = null;
      _clienteNombre = null;
      _montoPago = 0.0;
      _saldoRestante = 0.0;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_pagoId == null ? 'Registrar Pago' : 'Editar Pago'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('prestamos').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final prestamos = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    initialValue: _prestamoSeleccionado,
                    items: prestamos.map((p) {
                      final data = p.data() as Map<String, dynamic>;
                      final clienteNombre = data['clienteNombre'] ?? 'Desconocido';
                      final monto = data['monto'] ?? 0.0;
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text('$clienteNombre - S/${monto.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                    onChanged: (v) async {
                      setState(() {
                        _prestamoSeleccionado = v;
                      });

                      // Obtener saldo restante actual del préstamo
                      final doc = await FirebaseFirestore.instance
                          .collection('prestamos')
                          .doc(v)
                          .get();

                      if (doc.exists) {
                        final data = doc.data()!;
                        setState(() {
                          _clienteNombre = data['clienteNombre'];
                          _saldoRestante = (data['saldoRestante'] ?? data['totalPagar'] ?? 0).toDouble();
                        });
                      }
                    },
                    validator: (v) => v == null ? 'Selecciona un préstamo válido' : null,
                    decoration: const InputDecoration(labelText: 'Préstamo asociado'),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _montoPago > 0 ? _montoPago.toString() : '',
                decoration: InputDecoration(
                  labelText: 'Monto del pago (Saldo restante: S/${_saldoRestante.toStringAsFixed(2)})',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final monto = double.tryParse(v ?? '');
                  if (monto == null || monto <= 0) {
                    return 'Monto inválido';
                  }
                  if (monto > _saldoRestante) {
                    return 'El monto excede el saldo restante (S/${_saldoRestante.toStringAsFixed(2)})';
                  }
                  return null;
                },
                onSaved: (v) => _montoPago = double.parse(v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                final nuevoSaldo = _saldoRestante - _montoPago;

                final pagoData = {
                  'prestamoId': _prestamoSeleccionado,
                  'clienteNombre': _clienteNombre,
                  'monto': _montoPago,
                  'saldoRestante': nuevoSaldo,
                  'fecha': DateTime.now().toIso8601String(),
                };

                try {
                  if (_pagoId == null) {
                    await _firestoreService.agregarPago(pagoData);
                  } else {
                    await _firestoreService.actualizarPago(_pagoId!, pagoData);
                  }

                  // 🔹 Actualiza saldo del préstamo
                  await FirebaseFirestore.instance
                      .collection('prestamos')
                      .doc(_prestamoSeleccionado)
                      .update({
                    'saldoRestante': nuevoSaldo,
                    'estado': nuevoSaldo <= 0 ? 'Pagado' : 'Activo',
                  });

                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ==========================
  // Eliminar pago
  // ==========================
  void _eliminarPago(String id) async {
    await _firestoreService.eliminarPago(id);
  }

  // ==========================
  // UI PRINCIPAL
  // ==========================
  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');

    return Scaffold(
      appBar: AppBar(title: const Text('Pagos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.obtenerPagos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final pagos = snapshot.data!.docs;

          if (pagos.isEmpty) {
            return const Center(child: Text('No hay pagos registrados.'));
          }

          return ListView.builder(
            itemCount: pagos.length,
            itemBuilder: (context, index) {
              final pago = pagos[index].data() as Map<String, dynamic>;
              final fecha = DateTime.tryParse(pago['fecha'] ?? '');

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Cliente: ${pago['clienteNombre'] ?? 'Desconocido'}'),
                  subtitle: Text(
                    'Monto: ${formato.format(pago['monto'] ?? 0)}\n'
                    'Saldo restante: ${formato.format(pago['saldoRestante'] ?? 0)}\n'
                    'Fecha: ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'Sin fecha'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _mostrarDialogoPago(pagoExistente: pago),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarPago(pago['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoPago(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
