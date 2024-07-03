import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:ui' as ui; // Para utilizar el efecto de desenfoque

class ScreenVoiceCalling extends StatelessWidget {
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final VoidCallback onHangUp;
  final String callerName;
  final String callerNumber;
  final MediaStream? incomingStream;

  const ScreenVoiceCalling({
    required this.localRenderer,
    required this.remoteRenderer,
    required this.onHangUp,
    required this.callerName,
    required this.callerNumber,
    required this.incomingStream,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Color de fondo negro para toda la pantalla
      body: Stack(
        fit: StackFit.expand, // Hace que los elementos dentro del Stack ocupen todo el espacio disponible
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
                  'Llamada entrante de:',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  callerName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  callerNumber,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 20),
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
                onPressed: onHangUp,
                icon: Icon(Icons.call_end),
                label: Text('Colgar'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, 
                  backgroundColor: Color(0xFFEC5454), // Color de fondo del botón
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
