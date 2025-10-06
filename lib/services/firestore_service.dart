import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference clientesCollection =
      FirebaseFirestore.instance.collection('clientes');

  // Agregar cliente
  Future<void> agregarCliente(Map<String, dynamic> cliente) async {
    await clientesCollection.add(cliente);
  }

  // Obtener clientes en tiempo real
  Stream<QuerySnapshot> obtenerClientes() {
    return clientesCollection.snapshots();
  }

  // Actualizar cliente
  Future<void> actualizarCliente(String id, Map<String, dynamic> cliente) async {
    await clientesCollection.doc(id).update(cliente);
  }

  // Eliminar cliente
  Future<void> eliminarCliente(String id) async {
    await clientesCollection.doc(id).delete();
  }
}
