import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SolicitarPrestamoPage extends StatefulWidget {
  const SolicitarPrestamoPage({super.key});

  @override
  State<SolicitarPrestamoPage> createState() => _SolicitarPrestamoPageState();
}

class _SolicitarPrestamoPageState extends State<SolicitarPrestamoPage> {
  final _formKey = GlobalKey<FormState>();
  
  // --- CONTROLADORES (Datos Personales + Préstamo) ---
  final _nombreController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _correoController = TextEditingController(); // Solo lectura
  
  final _montoController = TextEditingController();
  final _plazoController = TextEditingController();
  
  bool _loading = false;
  int? _miScore; 

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _cargarDatosExistentes();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _correoController.dispose();
    _montoController.dispose();
    _plazoController.dispose();
    super.dispose();
  }

  /// Cargar datos si el cliente ya los llenó antes
  Future<void> _cargarDatosExistentes() async {
    final user = _auth.currentUser;
    if (user != null) {
      _correoController.text = user.email ?? '';

      // Buscar en la colección 'clientes' primero
      final docCliente = await _db.collection('clientes').doc(user.uid).get();
      
      if (docCliente.exists) {
        final data = docCliente.data()!;
        setState(() {
          _nombreController.text = data['nombre'] ?? '';
          _dniController.text = data['dni'] ?? '';
          _telefonoController.text = data['telefono'] ?? '';
          _direccionController.text = data['direccion'] ?? '';
        });
      }

      // Cargar score desde 'empleados' (donde se crea al registro)
      final docEmpleado = await _db.collection('empleados').doc(user.uid).get();
      if (docEmpleado.exists) {
        setState(() {
          _miScore = docEmpleado.data()?['scoreCrediticio'];
        });
      }
    }
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación simple de score
    if (_miScore != null && _miScore! < 500) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu score es muy bajo para solicitar créditos.')));
       return;
    }

    setState(() => _loading = true);

    try {
      final user = _auth.currentUser!;
      
      // 1. ACTUALIZAR/GUARDAR DATOS DEL CLIENTE (Para que el Analista lo vea)
      // Usamos set con Merge para no borrar datos si ya existen
      await _db.collection('clientes').doc(user.uid).set({
        'id': user.uid,
        'nombre': _nombreController.text.trim(),
        'dni': _dniController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'correo': user.email,
        'estado': 'activo', // Aseguramos que esté activo
        // Mantenemos fecha registro original si existe, o ponemos nueva
        'ultimaActualizacion': DateTime.now().toIso8601String(), 
      }, SetOptions(merge: true));

      // 2. GUARDAR LA SOLICITUD DE PRÉSTAMO
      await _db.collection('prestamos').add({
        'cliente': user.uid,
        'clienteNombre': _nombreController.text.trim(), // Guardamos nombre copia
        'clienteEmail': user.email,
        'dniNumero': _dniController.text.trim(),
        'monto': double.parse(_montoController.text),
        'plazoMeses': int.parse(_plazoController.text),
        'tasaInteres': 0.0, 
        'estado': 'Pendiente',
        'fechaRegistro': DateTime.now().toIso8601String(),
        'scoreAlMomento': _miScore,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Datos actualizados y solicitud enviada')));
        Navigator.pop(context);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Préstamo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN: SCORE ---
              if (_miScore != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.teal, size: 30),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tu Score Crediticio', style: TextStyle(color: Colors.teal)),
                          Text('$_miScore puntos', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),

              // --- SECCIÓN: DATOS PERSONALES (Igual a la imagen) ---
              const Text('Datos Personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(labelText: 'DNI', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: (v) => v!.length != 8 ? 'DNI inválido' : null,
              ),
              const SizedBox(height: 5),

              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _correoController,
                readOnly: true, // El correo no se edita aquí
                decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder(), filled: true, fillColor: Colors.white70),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),

              const Divider(height: 40, thickness: 2),

              // --- SECCIÓN: PRÉSTAMO ---
              const Text('Detalles del Préstamo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _montoController,
                      decoration: const InputDecoration(
                        labelText: 'Monto (S/.)', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _plazoController,
                      decoration: const InputDecoration(
                        labelText: 'Plazo (meses)', 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // BOTÓN
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _enviarSolicitud,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('GUARDAR Y SOLICITAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}