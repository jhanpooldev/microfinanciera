import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  // 🔹 CLIENTES
  Future<void> agregarCliente(Map<String, dynamic> cliente) async {
    // Validar duplicados por DNI o correo antes de registrar
    final existing = await _db
        .collection('clientes')
        .where('dni', isEqualTo: cliente['dni'])
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('El DNI ya está registrado.');
    }

    final existingEmail = await _db
        .collection('clientes')
        .where('correo', isEqualTo: cliente['correo'])
        .get();

    if (existingEmail.docs.isNotEmpty) {
      throw Exception('El correo ya está registrado.');
    }

    // Registrar cliente
    final String id = _uuid.v4();
    await _db.collection('clientes').doc(id).set({
      'id': id,
      ...cliente,
      'estado': 'activo',
      'fechaRegistro': DateTime.now().toIso8601String(),
    });
  }

  Stream<QuerySnapshot> obtenerClientes() {
    return _db.collection('clientes').orderBy('nombre').snapshots();
  }

  Future<void> actualizarCliente(String id, Map<String, dynamic> cliente) async {
    await _db.collection('clientes').doc(id).update(cliente);
  }

  Future<void> eliminarCliente(String id) async {
    await _db.collection('clientes').doc(id).delete();
  }

    // 🔹 PRÉSTAMOS
  Future<void> agregarPrestamo(Map<String, dynamic> prestamo) async {
    final String id = _uuid.v4();
    await _db.collection('prestamos').doc(id).set({
      'id': id,
      ...prestamo,
      'fecha': DateTime.now().toIso8601String(),
      'estado': 'activo',
    });
  }

  Stream<QuerySnapshot> obtenerPrestamos() {
    return _db.collection('prestamos').orderBy('fecha', descending: true).snapshots();
  }

  Future<void> actualizarPrestamo(String id, Map<String, dynamic> prestamo) async {
    await _db.collection('prestamos').doc(id).update(prestamo);
  }

  Future<void> eliminarPrestamo(String id) async {
    await _db.collection('prestamos').doc(id).delete();
  }


     // 🔹 EMPLEADOS
  Future<void> agregarEmpleado(Map<String, dynamic> empleado) async {
    final String id = _uuid.v4();

    // Validaciones
    if (empleado['correo'] == null || !empleado['correo'].toString().contains('@')) {
      throw Exception('Correo no válido');
    }
    if (empleado['sueldo'] == null || double.tryParse(empleado['sueldo'].toString())! <= 0) {
      throw Exception('El sueldo debe ser mayor que 0');
    }

    // Validar correo único
    final existing = await _db
        .collection('empleados')
        .where('correo', isEqualTo: empleado['correo'])
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('El correo ya está registrado');
    }

    await _db.collection('empleados').doc(id).set({
      'id': id,
      ...empleado,
      'fechaRegistro': DateTime.now().toIso8601String(),
    });
  }

  Stream<QuerySnapshot> obtenerEmpleados() {
    return _db.collection('empleados').orderBy('nombre').snapshots();
  }

  Future<void> actualizarEmpleado(String id, Map<String, dynamic> empleado) async {
    await _db.collection('empleados').doc(id).update(empleado);
  }

  Future<void> eliminarEmpleado(String id) async {
    await _db.collection('empleados').doc(id).delete();
  }



  // 🔹 PAGOS
  Future<void> agregarPago(Map<String, dynamic> pago) async {
    final String id = _uuid.v4();

    final double monto = double.tryParse(pago['monto'].toString()) ?? 0;
    final double saldoRestante = double.tryParse(pago['saldoRestante'].toString()) ?? 0;

    if (monto <= 0) {
      throw Exception('El monto debe ser mayor a 0');
    }
    if (monto > saldoRestante) {
      throw Exception('El monto no puede ser mayor al saldo restante');
    }

    await _db.collection('pagos').doc(id).set({
      'id': id,
      ...pago,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  Stream<QuerySnapshot> obtenerPagos() {
    return _db.collection('pagos').orderBy('fecha', descending: true).snapshots();
  }

  Future<void> actualizarPago(String id, Map<String, dynamic> pago) async {
    await _db.collection('pagos').doc(id).update(pago);
  }

  Future<void> eliminarPago(String id) async {
    await _db.collection('pagos').doc(id).delete();
  }
}