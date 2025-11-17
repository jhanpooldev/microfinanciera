import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage();

  static Future<void> guardarSesion(String email, String rol) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'rol', value: rol);
  }

  static Future<Map<String, String?>> obtenerSesion() async {
    final email = await _storage.read(key: 'email');
    final rol = await _storage.read(key: 'rol');
    return {'email': email, 'rol': rol};
  }

  static Future<void> cerrarSesion() async {
    await _storage.deleteAll();
  }
}
