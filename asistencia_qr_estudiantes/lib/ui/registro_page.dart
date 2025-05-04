import 'package:asistencia_qr_estudiantes/ui/escaner_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();

  void guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombreCtrl.text.trim());
    await prefs.setString('apellido', apellidoCtrl.text.trim());
    await prefs.setBool('registrado', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EscanerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Estudiante')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Completa tus datos para registrar tu asistencia con QR',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: apellidoCtrl,
              decoration: InputDecoration(
                labelText: 'Apellido',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Guardar y continuar'),
              onPressed: guardarDatos,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
