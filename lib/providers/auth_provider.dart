import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? email;
  String rol = 'Invitado';
  bool isLoggedIn = false;

  Future<void> login(String email, String password) async {
    final user = await _authService.login(email, password);
    if (user != null) {
      final rolUsuario = await _authService.obtenerRol(email);
      rol = rolUsuario ?? 'Invitado';
      this.email = email;
      isLoggedIn = true;
      await SessionManager.guardarSesion(email, rol);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await SessionManager.cerrarSesion();
    await _authService.logout();
    email = null;
    rol = 'Invitado';
    isLoggedIn = false;
    notifyListeners();
  }

  Future<void> cargarSesion() async {
    final sesion = await SessionManager.obtenerSesion();
    email = sesion['email'];
    rol = sesion['rol'] ?? 'Invitado';
    isLoggedIn = email != null;
    notifyListeners();
  }
}
