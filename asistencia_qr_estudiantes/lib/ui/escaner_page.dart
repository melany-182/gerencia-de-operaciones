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

class _EscanerPageState extends State<EscanerPage>
    with SingleTickerProviderStateMixin {
  bool validando = false;
  String mensaje = "";
  String? nombreCompleto;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString('nombre') ?? "";
    final apellido = prefs.getString('apellido') ?? "";
    setState(() {
      nombreCompleto = "$nombre $apellido";
    });
  }

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

        debugPrint("🟢 Respuesta de Google Sheets: ${response.body}");
        setState(() => mensaje = "✅ Asistencia registrada correctamente");
      } else {
        setState(() => mensaje = "❌ Estás demasiado lejos del aula");
      }
    } catch (e) {
      setState(() => mensaje = "⚠️ Error al procesar el código QR");
      debugPrint("❌ Error: $e");
    }

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      setState(() => mensaje = "");
    }
    validando = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    radius: 20,
                    child: Text(
                      nombreCompleto != null && nombreCompleto!.isNotEmpty
                          ? nombreCompleto![0].toUpperCase()
                          : "?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${nombreCompleto ?? "Estudiante"}',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Escanea para registrar asistencia',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _scannerController.start(),
                    tooltip: 'Reiniciar escáner',
                  ),
                ],
              ),
            ),

            // Scanner Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Scanner
                              MobileScanner(
                                controller: _scannerController,
                                onDetect: (capture) {
                                  final barcode = capture.barcodes.first;
                                  if (barcode.rawValue != null) {
                                    validarQR(barcode.rawValue!);
                                  }
                                },
                              ),

                              // Scanner Overlay
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: Size(
                                      MediaQuery.of(context).size.width * 0.7,
                                      MediaQuery.of(context).size.width * 0.7,
                                    ),
                                    painter: ScannerOverlayPainter(
                                      animation: _animation.value,
                                      validando: validando,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Status Message
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: _getStatusColor(),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              mensaje.isEmpty
                                  ? 'Apunta la cámara al código QR del docente'
                                  : mensaje,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: _getStatusColor(),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Info
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'La asistencia se registrará automáticamente cuando escanees un código QR válido y estés dentro del rango permitido.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (mensaje.isEmpty) {
      return Theme.of(context).colorScheme.primary;
    } else if (mensaje.startsWith("✅")) {
      return Colors.green;
    } else if (mensaje.startsWith("❌")) {
      return Colors.red;
    } else if (mensaje.startsWith("⏳")) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    if (mensaje.isEmpty) {
      return Icons.qr_code_scanner;
    } else if (mensaje.startsWith("✅")) {
      return Icons.check_circle;
    } else if (mensaje.startsWith("❌")) {
      return Icons.error;
    } else if (mensaje.startsWith("⏳")) {
      return Icons.hourglass_top;
    } else {
      return Icons.info;
    }
  }
}

// Custom Painter for Scanner Overlay
class ScannerOverlayPainter extends CustomPainter {
  final double animation;
  final bool validando;
  final Color color;

  ScannerOverlayPainter({
    required this.animation,
    required this.validando,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final cornerSize = width * 0.1;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

    // Draw corners
    // Top left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerSize)
        ..lineTo(0, 0)
        ..lineTo(cornerSize, 0),
      paint,
    );

    // Top right
    canvas.drawPath(
      Path()
        ..moveTo(width - cornerSize, 0)
        ..lineTo(width, 0)
        ..lineTo(width, cornerSize),
      paint,
    );

    // Bottom left
    canvas.drawPath(
      Path()
        ..moveTo(0, height - cornerSize)
        ..lineTo(0, height)
        ..lineTo(cornerSize, height),
      paint,
    );

    // Bottom right
    canvas.drawPath(
      Path()
        ..moveTo(width - cornerSize, height)
        ..lineTo(width, height)
        ..lineTo(width, height - cornerSize),
      paint,
    );

    // Draw scan line if not validating
    if (!validando) {
      final scanPaint =
          Paint()
            ..color = color.withOpacity(0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;

      final y = height * animation;
      canvas.drawLine(Offset(0, y), Offset(width, y), scanPaint);
    } else {
      // Draw pulsing circle if validating
      final circlePaint =
          Paint()
            ..color = color.withOpacity(0.3 + (animation * 0.3))
            ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(width / 2, height / 2),
        width * 0.3 * (0.8 + (animation * 0.2)),
        circlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.validando != validando ||
        oldDelegate.color != color;
  }
}
