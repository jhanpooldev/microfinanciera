import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/clientes_page.dart';
import 'pages/prestamos_page.dart';
import 'pages/empleados_page.dart';
import 'pages/pagos_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomePage(),
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
  '/home': (context) => const HomePage(),
  '/clientes': (context) =>  ClientesPage(),
  '/prestamos': (context) =>  PrestamosPage(),
  '/empleados': (context) => const EmpleadosPage(),
  '/pagos': (context) => const PagosPage(),
};
