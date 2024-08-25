import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async'; // Import para Timer
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:segucom_app/configBackend.dart'; // Para utilizar el efecto de desenfoque

class ScreenVoiceCalling extends StatefulWidget {
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final VoidCallback onHangUp;
  final String callerName;
  final String callerNumber;
  final MediaStream? incomingStream;
  final String me; // Nuevo parámetro
  final String destinatario; // Nuevo parámetro

  const ScreenVoiceCalling({
    required this.localRenderer,
    required this.remoteRenderer,
    required this.onHangUp,
    required this.callerName,
    required this.callerNumber,
    required this.incomingStream,
    required this.me, // Requerido
    required this.destinatario, // Requerido
  });

  @override
  _ScreenVoiceCallingState createState() => _ScreenVoiceCallingState();
}

class _ScreenVoiceCallingState extends State<ScreenVoiceCalling> {
  bool isDisponibility = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkDisponibilityPeriodically();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el temporizador cuando se cierre la pantalla
    super.dispose();
  }

  void _checkDisponibilityPeriodically() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) async {
      var response = await checkDisponibility(
        widget.me, // Usar el nuevo parámetro me
        widget.destinatario, // Usar el nuevo parámetro destinatario
      );
      if (response == 200) {
        setState(() {
          isDisponibility = response == 200;
        });
      }
      if (response == 400) {
        widget.onHangUp();
        setState(() {
          isDisponibility = response == 200;
          //ejecutar aqui
        });
      }
      print(
          '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  isDisponibility calling: $response');
    });
  }

// ----------------------------------------------------------------------------- function para comprobar disponibilidad de llamadas
  Future<int> checkDisponibility(String me, String destinatario) async {
    var url =
        '${ConfigBackend.backendUrlComunication}/check-chatroom-status/$me/$destinatario';
    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ calliing: " + url);
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      // Regresar el statusCode
      return response.statusCode;
    } catch (e) {
      print('Error sending message: $e');
      // Regresar un código de estado de error, por ejemplo, 500
      return 500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Color de fondo negro para toda la pantalla
      body: Stack(
        fit: StackFit
            .expand, // Hace que los elementos dentro del Stack ocupen todo el espacio disponible
        children: [
          // Fondo con efecto de desenfoque y margen
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/fondoCall.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Container(
                  color: Colors.black.withOpacity(0.0), // Opacidad del fondo
                ),
              ),
            ),
          ),
          // Contenido central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Ícono del usuario
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('lib/assets/iconUser.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Información de la llamada en color blanco
                Text(
                  'Llamada de voz en curso',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  widget.callerName,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  widget.callerNumber,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 20),
                // Mostrar disponibilidad
                Text(
                  'Disponibilidad: ${isDisponibility ? "Disponible" : "No disponible"}',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          // Botón de colgar personalizado alineado en la parte inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 35,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: widget.onHangUp,
                icon: Icon(Icons.call_end),
                label: Text('Colgar'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      Color(0xFFEC5454), // Color de fondo del botón
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
