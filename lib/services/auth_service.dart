import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Iniciar sesión con correo y contraseña
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verificar si el usuario tiene rol registrado
      await obtenerRol(email);

      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Error FirebaseAuth: ${e.code}');
      rethrow;
    } catch (e) {
      print('🔥 Error general al iniciar sesión: $e');
      return null;
    }
  }

  /// 🔹 Registrar nuevo usuario (solo Gerente puede asignar roles especiales)
  Future<User?> registrarEmpleado(String email, String password, String rol, {String? creadorUid}) async {
    try {
      // Validar si quien intenta crear es el gerente
      if (rol != 'Usuario' && creadorUid != 'VRPWf7b16rPACvfhosQzX86P9hI2') {
        throw Exception('Solo el gerente puede asignar roles especiales');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Usuario no creado correctamente');

      // Guardar datos del usuario en Firestore
      await _db.collection('empleados').doc(user.uid).set({
        'correo': email,
        'rol': rol,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'creadoPor': creadorUid ?? user.uid,
      });

      print('✅ Usuario $email registrado como $rol en Firestore');
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Error FirebaseAuth: ${e.code}');
      rethrow;
    } catch (e) {
      print('🔥 Error general al registrar empleado: $e');
      rethrow;
    }
  }

  /// 🔹 Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 🔹 Obtener el rol de un usuario por su correo
  Future<String?> obtenerRol(String email) async {
    try {
      final snapshot = await _db
          .collection('empleados')
          .where('correo', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        print('🟢 Rol obtenido: ${data['rol']}');
        return data['rol'] ?? 'Invitado';
      } else {
        print('⚠️ Usuario sin rol asignado');
        return 'Invitado';
      }
    } catch (e) {
      print('🔥 Error obteniendo rol: $e');
      return 'Invitado';
    }
  }

  /// 🔹 Obtener el usuario actual
  User? get usuarioActual => _auth.currentUser;
}