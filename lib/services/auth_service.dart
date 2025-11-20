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

  /// 🔹 Registrar nuevo usuario (Usuario/Cliente libre, otros roles restringidos)
  Future<User?> registrarEmpleado(String email, String password, String rol, {String? creadorUid}) async {
    try {
      // 🛑 VALIDACIÓN DE ROLES
      // Permitimos registro libre para 'Usuario' y 'Cliente'.
      // Para roles administrativos (Gerente, Asesor, etc.), se requiere el ID del gerente (creadorUid).
      if (rol != 'Usuario' && rol != 'Cliente' && creadorUid != 'VRPWf7b16rPACvfhosQzX86P9hI2') {
        throw Exception('Solo el gerente puede asignar roles especiales');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Usuario no creado correctamente');

      // 🟢 DATOS INICIALES
      // Si es Cliente, le damos un score inicial de 1000.
      final int? scoreInicial = (rol == 'Cliente') ? 1000 : null;

      // Guardar datos del usuario en Firestore (colección 'empleados' usada como 'usuarios')
      await _db.collection('empleados').doc(user.uid).set({
        'correo': email,
        'rol': rol,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'creadoPor': creadorUid ?? user.uid,
        'scoreCrediticio': scoreInicial, // 👈 Aquí se guarda el score inicial
      });

      print('✅ Usuario $email registrado como $rol en Firestore con score: $scoreInicial');
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Error FirebaseAuth: ${e.code}');
      rethrow;
    } catch (e) {
      print('🔥 Error general al registrar usuario: $e');
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