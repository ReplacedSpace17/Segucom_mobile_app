import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:segucom_app/Services_background/UbicationService.dart';
import 'package:segucom_app/configBackend.dart';
import 'package:segucom_app/screens/NotificationsClass/NotificationHome.dart';
import 'package:volume_watcher/volume_watcher.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:segucom_app/configBackend.dart';

class VolumeService {
  bool alertShowing = false;
  bool isCooldownActive =
      false; // Indica si el temporizador de enfriamiento está activo
  double currentVolume = 1.0;
  Timer? _alertCooldownTimer; // Temporizador para enfriar el período de alerta

  late Position _currentPosition;
  late DateTime _currentDateTime;

  // Nuevos atributos para almacenar datos
  final String numElemento;
  final String numTelefono;

  VolumeService(this.numElemento, this.numTelefono) {
    VolumeWatcher.setVolume(0.5); // Inicializa el volumen al 50%
    VolumeWatcher.addListener(_onVolumeChanged);
  }

  void _onVolumeChanged(double volume) {
    print("Current Volume: $volume");

    if (volume >= 0.95) {
      if (!isCooldownActive) {
        // Si el enfriamiento no está activo, muestra la alerta y activa el enfriamiento
        if (!alertShowing) {
          _showPanicAlert();
          alertShowing = true;
        }
        _startAlertCooldown();
      } else {
        // Si el enfriamiento está activo, solo ajusta el volumen
        VolumeWatcher.setVolume(0.5);
        print('Volume set to 0.5 due to cooldown.');
      }
    } else {
      // Restablece alertShowing si el volumen cae por debajo del umbral
      alertShowing = false;
    }
    currentVolume = volume;
  }

  Future<void> _showPanicAlert() async {
    NotificationController.createNewNotification("Botón de pánico", "Se ha enviado una alerta ");
    _currentDateTime = DateTime.now();
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );
      _currentPosition = position;

      if (_currentPosition != null) {
        // Construir el cuerpo de la petición
        String Ubicacion = "lat:" +
            _currentPosition.latitude.toString() +
            ",lon:" +
            _currentPosition.longitude.toString();
        print(Ubicacion);

        final url = Uri.parse(
          ConfigBackend.backendUrlComunication + '/segucomunication/api/alerta',
        );
        print(url);
        final body = {
          "ALARMA_FEC": _currentDateTime.toIso8601String(),
          "ELEMENTO_NUMERO": numElemento, // Usar atributo de instancia
          "ELEMENTO_TEL_NUMERO": numTelefono, // Usar atributo de instancia
          "ALARMA_UBICA": Ubicacion,
        };
        print('Enviando ubicación al servidor ... ' + body.toString());

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 201) {
          // NotificationController.createNewNotification("Hola", "Ubicacion enviada");
          print('Alerta enviada al servidor');
          
          VolumeWatcher.setVolume(0.6);
        } else {
          print('Error al enviar alerta: ${response.statusCode}');
        }
      } else {
        // NotificationController.createNewNotification("NO", "No obtuvo la ubi en segundo plano");
      }
    } catch (e) {
      print("Error al obtener la ubicación: $e");
    }

    print('Adjusted volume to 0.6');
  }

  void _startAlertCooldown() {
    isCooldownActive = true; // Activa el estado de enfriamiento
    _alertCooldownTimer?.cancel(); // Cancela el temporizador anterior si existe

    _alertCooldownTimer = Timer(const Duration(seconds: 5), () {
      // Después de 5 segundos, desactiva el enfriamiento y ajusta el volumen
      isCooldownActive = false;
      VolumeWatcher.setVolume(0.5);
      print('Alert cooldown finished, volume set to 0.5.');
    });
  }

  void dispose() {
    VolumeWatcher.removeListener(_onVolumeChanged as int?);
    _alertCooldownTimer?.cancel();
  }
}
