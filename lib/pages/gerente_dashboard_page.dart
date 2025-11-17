import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GerenteDashboardPage extends StatefulWidget {
  const GerenteDashboardPage({super.key});

  @override
  State<GerenteDashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<GerenteDashboardPage> {
  final _db = FirebaseFirestore.instance;

  int clientes = 0;
  int prestamosActivos = 0;
  double montoTotal = 0;
  double totalPagos = 0;
  int prestamosPagados = 0;

  Map<String, int> prestamosPorMes = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      // 🔹 Clientes
      final clientesSnap = await _db.collection('clientes').get();
      clientes = clientesSnap.size;

      // 🔹 Préstamos
      final prestamosSnap = await _db.collection('prestamos').get();
      prestamosActivos = prestamosSnap.docs
          .where((d) => d['estado'] == 'Activo')
          .length;
      prestamosPagados = prestamosSnap.docs
          .where((d) => d['estado'] == 'Pagado')
          .length;

      montoTotal = prestamosSnap.docs
          .where((d) => d['estado'] == 'Activo')
          .fold(0.0, (sum, doc) => sum + (doc['monto'] ?? 0));

      // 🔹 Pagos
      final pagosSnap = await _db.collection('pagos').get();
      totalPagos =
          pagosSnap.docs.fold(0.0, (sum, doc) => sum + (doc['monto'] ?? 0));

      // 🔹 Créditos por mes
      prestamosPorMes.clear();
      for (var doc in prestamosSnap.docs) {
        final fecha = DateTime.tryParse(doc['fecha'] ?? '');
        if (fecha != null) {
          final mes = DateFormat('MM/yyyy').format(fecha);
          prestamosPorMes[mes] = (prestamosPorMes[mes] ?? 0) + 1;
        }
      }

      // Ordenar por fecha (últimos 6 meses)
      final sorted = prestamosPorMes.entries.toList()
        ..sort((a, b) =>
            DateFormat('MM/yyyy').parse(a.key).compareTo(DateFormat('MM/yyyy').parse(b.key)));
      prestamosPorMes = Map.fromEntries(sorted.takeLast(6));

      setState(() => loading = false);
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📊 Dashboard Gerencial')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Indicadores Principales',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildKpiRow(),
                  const Divider(height: 30),
                  const Text(
                    'Distribución de Préstamos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildPieChart(),
                  const Divider(height: 30),
                  const Text(
                    'Créditos Registrados por Mes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildBarChart(),
                ],
              ),
            ),
    );
  }

  /// 📌 Tarjetas de KPIs
  Widget _buildKpiRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildKpiCard(Icons.people, 'Clientes', clientes.toString(), Colors.teal),
        _buildKpiCard(Icons.credit_card, 'Préstamos activos',
            prestamosActivos.toString(), Colors.orange),
        _buildKpiCard(Icons.attach_money, 'Monto total',
            'S/ ${montoTotal.toStringAsFixed(2)}', Colors.blue),
        _buildKpiCard(Icons.payments, 'Pagos recibidos',
            'S/ ${totalPagos.toStringAsFixed(2)}', Colors.green),
      ],
    );
  }

  Widget _buildKpiCard(IconData icon, String label, String value, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 20,
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// 🥧 Gráfico circular de distribución
  Widget _buildPieChart() {
    final total = prestamosActivos + prestamosPagados;
    if (total == 0) {
      return const Center(child: Text('No hay préstamos registrados.'));
    }

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.teal,
              value: prestamosActivos.toDouble(),
              title:
                  'Activos\n${((prestamosActivos / total) * 100).toStringAsFixed(1)}%',
              radius: 80,
            ),
            PieChartSectionData(
              color: Colors.orange,
              value: prestamosPagados.toDouble(),
              title:
                  'Pagados\n${((prestamosPagados / total) * 100).toStringAsFixed(1)}%',
              radius: 80,
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Gráfico de barras: créditos por mes
  Widget _buildBarChart() {
    if (prestamosPorMes.isEmpty) {
      return const Center(child: Text('Sin datos de préstamos mensuales.'));
    }

    final meses = prestamosPorMes.keys.toList();
    final valores = prestamosPorMes.values.toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= meses.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      meses[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(
            meses.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: valores[i].toDouble(),
                  color: Colors.teal,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _TakeLast<K, V> on List<MapEntry<K, V>> {
  List<MapEntry<K, V>> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
