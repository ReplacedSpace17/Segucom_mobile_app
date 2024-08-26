import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:segucom_app/RequestIncompatibility.dart';
import 'package:segucom_app/screens/App.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestPermissionScreen extends StatefulWidget {
  @override
  _RequestPermissionScreenState createState() =>
      _RequestPermissionScreenState();
}

class _RequestPermissionScreenState extends State<RequestPermissionScreen> {
  @override
  void initState() {
    _showPermissionDialog();
    super.initState();
  }

  Future<void> _showPermissionDialog() async {
    final bool? shouldRequest = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Permisos necesarios',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'La presente aplicación está diseñada para recopilar datos de ubicación con el propósito de habilitar funcionalidades de seguimiento y monitoreo de geocercas, incluso cuando la aplicación se encuentra cerrada o no está en uso. Esta capacidad permite una supervisión continua y eficiente de los elementos dentro de las áreas definidas, asegurando una gestión eficaz de la seguridad y el cumplimiento de los protocolos establecidos. Adicionalmente se utiliza el micrófono y la cámara cuando se haga uso del módulo de mensajería ¿Deseas otorgar acceso?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Aceptar', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldRequest == true) {
      await _requestPermissions();
    } else {
      print('Permisos no otorgados');
    }
  }
Future<void> _requestPermissions() async {
  print("Abriendo la configuración de ubicación...");
  // Abre la configuración de ubicación
  await Geolocator.openLocationSettings();

  // Verificar y solicitar el permiso de ubicación
  print("Verificando permisos de ubicación...");
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    // Si el permiso fue denegado, solicítalo
    print("Permiso de ubicación denegado, solicitando permiso...");
    permission = await Geolocator.requestPermission();
  }

  // Verifica si el permiso fue otorgado
  if (permission == LocationPermission.always) {
    // Permisos de ubicación concedidos
    print("Permisos de ubicación concedidos.");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('configPermissions', 'true');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MyAppIncompatibility()),
    );
    // Navega a HomeScreen sin usar Navigator 
   /* Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
    */
  } else if (permission == LocationPermission.deniedForever) {
    // Permiso de ubicación denegado permanentemente
    print("Permiso de ubicación denegado permanentemente.");
    _showLocationPermissionAlert();
  } else {
    // Permiso de ubicación no concedido
    print("Permiso de ubicación no concedido.");
    _showLocationPermissionAlert();
  }

  // Solicitar permisos de notificaciones, micrófono y cámara
  print("Solicitando permisos de notificaciones, micrófono y cámara...");
  await AwesomeNotifications().requestPermissionToSendNotifications();
  await Permission.microphone.request();
  await Permission.camera.request();
}

Future<void> _showLocationPermissionAlert() async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Permiso de Ubicación Requerido'),
        content: Text(
          'Por favor, activa el permiso de ubicación siempre en la configuración de la aplicación.',
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Abrir Configuración', style: TextStyle(color: Colors.blue)),
            onPressed: () {
              // Abre la configuración de la aplicación
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Aceptar', style: TextStyle(color: Colors.blue)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración Inicial',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 19, 55, 116),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Por favor, otorga los permisos necesarios.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 100,
                height: 100,
                child: ElevatedButton(
                  onPressed: () {
                    _showPermissionDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 19, 55, 116),
                    shape: CircleBorder(),
                  ),
                  child: Text(
                    'Verificar',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
