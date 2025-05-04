import 'package:asistencia_qr_estudiantes/ui/escaner_page.dart';
import 'package:asistencia_qr_estudiantes/ui/registro_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AsistenciaApp());
}

class AsistenciaApp extends StatelessWidget {
  const AsistenciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Asistencia QR - Estudiantes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final prefs = snapshot.data!;
          final registrado = prefs.getBool('registrado') ?? false;
          return registrado ? const EscanerPage() : const RegistroPage();
        },
      ),
    );
  }
}
