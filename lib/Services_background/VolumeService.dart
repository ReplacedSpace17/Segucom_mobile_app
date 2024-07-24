import 'package:segucom_app/screens/NotificationsClass/NotificationHome.dart';
import 'package:volume_watcher/volume_watcher.dart';
import 'dart:async';

class VolumeService {
  bool alertShowing = false;
  bool isCooldownActive = false; // Indica si el temporizador de enfriamiento está activo
  double currentVolume = 1.0;
  Timer? _alertCooldownTimer; // Temporizador para enfriar el período de alerta

  VolumeService() {
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

  void _showPanicAlert() {
    NotificationController.createNewNotification("Hola", "BOTON");
    VolumeWatcher.setVolume(0.6);
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
