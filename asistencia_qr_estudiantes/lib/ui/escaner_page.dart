import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EscanerPage extends StatefulWidget {
  const EscanerPage({super.key});

  @override
  State<EscanerPage> createState() => _EscanerPageState();
}

class _EscanerPageState extends State<EscanerPage> {
  bool validando = false;
  String mensaje = "";

  Future<void> validarQR(String qrText) async {
    if (validando) return;
    validando = true;
    setState(() => mensaje = "⏳ Validando ubicación...");

    try {
      final qrData = jsonDecode(qrText);
      final qrLat = qrData['lat'];
      final qrLng = qrData['lng'];
      final classId = qrData['classId'];

      if (await Permission.location.request().isDenied) {
        setState(() => mensaje = "❌ Permiso de ubicación denegado");
        validando = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final distancia = Geolocator.distanceBetween(
        qrLat,
        qrLng,
        position.latitude,
        position.longitude,
      );

      final prefs = await SharedPreferences.getInstance();
      final nombre = prefs.getString('nombre') ?? "";
      final apellido = prefs.getString('apellido') ?? "";

      if (distancia <= 50) {
        // final fecha = DateTime.now().toIso8601String();

        final response = await http.post(
          Uri.parse(
            'https://script.google.com/macros/s/AKfycbzN8Ce2atUS08JyvlhrOmsreGl50ndp6EmE4m2eyZrnoH1RTNBLfD5_DD_K18p5guFp/exec',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': nombre,
            'apellido': apellido,
            'clase': classId,
            'latitud': position.latitude,
            'longitud': position.longitude,
            'distancia': distancia,
          }),
        );

        print("🟢 Respuesta de Google Sheets: ${response.body}");
        setState(() => mensaje = "✅ Asistencia registrada correctamente");
      } else {
        setState(() => mensaje = "❌ Estás demasiado lejos del aula");
      }
    } catch (e) {
      setState(() => mensaje = "⚠️ Error al procesar el código QR");
      print("❌ Error: $e");
    }

    await Future.delayed(const Duration(seconds: 4));
    setState(() => mensaje = "");
    validando = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escáner de Asistencia')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first;
                    if (barcode.rawValue != null) {
                      validarQR(barcode.rawValue!);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Column(
                children: [
                  Text(
                    mensaje,
                    style: TextStyle(
                      fontSize: 18,
                      color:
                          mensaje.startsWith("✅")
                              ? Colors.green
                              : mensaje.startsWith("❌")
                              ? Colors.red
                              : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Escanea el código QR que el docente proyecta en el aula',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
