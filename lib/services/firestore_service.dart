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
      'estado': 'activo', // O 'Pendiente' si usas el flujo de aprobación
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
    return _db.collection('empleados').orderBy('nombre').snapshots(); // Nota: Asegúrate que tus documentos tengan campo 'nombre' o cambia por 'correo'
  }

  Future<void> actualizarEmpleado(String id, Map<String, dynamic> empleado) async {
    await _db.collection('empleados').doc(id).update(empleado);
  }

  Future<void> eliminarEmpleado(String id) async {
    await _db.collection('empleados').doc(id).delete();
  }

  // 🔹 PAGOS (CON LÓGICA DE PENALIZACIÓN)
  Future<void> agregarPago(Map<String, dynamic> pago) async {
    final String id = _uuid.v4();

    // Validaciones de monto
    final double monto = double.tryParse(pago['monto'].toString()) ?? 0;
    final double saldoRestante = double.tryParse(pago['saldoRestante'].toString()) ?? 0;

    if (monto <= 0) {
      throw Exception('El monto debe ser mayor a 0');
    }
    // Nota: A veces el saldo restante que viene del UI no está actualizado, 
    // pero mantenemos la validación si confías en el dato entrante.
    if (monto > saldoRestante) { 
      throw Exception('El monto no puede ser mayor al saldo restante');
    }

    // 1. Obtener datos del préstamo para verificar fechas y cliente
    final prestamoId = pago['prestamoId'];
    final prestamoDoc = await _db.collection('prestamos').doc(prestamoId).get();
    
    if (!prestamoDoc.exists) {
      throw Exception('El préstamo asociado no existe');
    }

    final prestamoData = prestamoDoc.data()!;

    // 2. Calcular fecha límite aproximada
    // Usamos 'fechaAprobacion' si existe (más exacto), sino 'fecha' (registro)
    final String fechaBaseStr = prestamoData['fechaAprobacion'] ?? prestamoData['fecha'] ?? DateTime.now().toIso8601String();
    final DateTime fechaInicio = DateTime.parse(fechaBaseStr);
    final int plazoMeses = int.tryParse(prestamoData['plazoMeses']?.toString() ?? '1') ?? 1;

    // Calculamos fecha límite (Fecha inicio + Plazo). 
    // Se asume 30 días por mes para simplificar.
    final fechaLimite = fechaInicio.add(Duration(days: 30 * plazoMeses));
    final fechaPago = DateTime.now();
    
    bool esPagoTardio = fechaPago.isAfter(fechaLimite);

    // 3. Lógica de Penalización en Score
    if (esPagoTardio) {
      final clienteUid = prestamoData['cliente']; // ID del usuario/cliente
      if (clienteUid != null) {
        // Bajamos 50 puntos por morosidad en la colección 'empleados'
        // (donde guardamos a los usuarios registrados con Auth)
        await _db.collection('empleados').doc(clienteUid).update({
          'scoreCrediticio': FieldValue.increment(-50),
        });
        print('⚠️ Penalización aplicada al cliente $clienteUid por pago tardío');
      }
    } else {
      // Opcional: Subir puntos por pago a tiempo
      // final clienteUid = prestamoData['cliente'];
      // await _db.collection('empleados').doc(clienteUid).update({
      //   'scoreCrediticio': FieldValue.increment(10),
      // });
    }

    // 4. Registrar el pago
    await _db.collection('pagos').doc(id).set({
      'id': id,
      ...pago,
      'fecha': fechaPago.toIso8601String(),
      'pagadoTarde': esPagoTardio,
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