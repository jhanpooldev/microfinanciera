// lib/services/auth_service.dart  (simulado)
import 'package:flutter/foundation.dart';

class AuthService {
  final Map<String, String> _fakeUser = {
    'email': 'admin@example.com',
    'password': '123456',
  };

  bool login(String email, String password) {
    return email == _fakeUser['email'] && password == _fakeUser['password'];
  }

  void loginAsGuest() {}

  bool register(String email, String password) {
    if (email == _fakeUser['email']) return false;
    _fakeUser['email'] = email;
    _fakeUser['password'] = password;
    return true;
  }

  // método añadido
  Future<void> logout() async {
    // si guardas estado local, limpialo aquí; solo simulamos delay
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('Simulated logout');
  }
}
