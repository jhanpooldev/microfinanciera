import 'package:flutter/material.dart';
import 'package:microfinanciera/pages/setup_gerente_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/clientes_page.dart';
import 'pages/prestamos_page.dart';
import 'pages/empleados_page.dart';
import 'pages/pagos_page.dart';
import 'pages/gerente_dashboard_page.dart';
import 'pages/gerente_home_page.dart';
import 'pages/home_cliente_page.dart';
import 'pages/solicitar_prestamo_page.dart';
import 'pages/aprobacion_prestamos_page.dart';
import 'pages/home_asesor_page.dart'; 

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomePage(),
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
  '/home': (context) => const HomePage(),
  '/clientes': (context) =>  ClientesPage(),
  '/prestamos': (context) =>  PrestamosPage(),
  '/empleados': (context) => const EmpleadosPage(),
  '/pagos': (context) => const PagosPage(),
  '/setup': (context) =>  SetupGerentePage(),
  '/dashboard': (_) => const GerenteDashboardPage(),
  '/gerente_home': (context) => const GerenteHomePage(),
  '/home_cliente': (context) =>  HomeClientePage(),
  '/solicitar_prestamo': (context) => SolicitarPrestamoPage(),
  '/aprobar_prestamos': (context) => AprobacionPrestamosPage(),
  '/home_asesor': (context) => HomeAsesorPage(), // Esta es la que fallaba

};
