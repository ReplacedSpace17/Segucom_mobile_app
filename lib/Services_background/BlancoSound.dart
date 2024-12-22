import 'package:just_audio/just_audio.dart';

class BlancoService {
  static final BlancoService _instance = BlancoService._internal();

  factory BlancoService() => _instance;

  BlancoService._internal() {
    // Escuchar cambios en el estado de reproducción
    _audioPlayer.playerStateStream.listen((playerState) {
      // Si no se está reproduciendo, vuelve a reproducir
      if (!playerState.playing) {
        playRingtone();
      }
    });

    // Escuchar cambios en el estado del audio
    _audioPlayer.playingStream.listen((isPlaying) {
      if (!isPlaying) {
        // Aquí puedes añadir la lógica para saber si un video se ha detenido
        // o si se debería reanudar la reproducción del ringtone
        _resumeRingtoneIfNeeded();
      }
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;

  void playRingtone() {
    _audioPlayer.setAsset('lib/assets/BLANCO.mp3').then((_) {
      // Establece el modo de bucle
      _audioPlayer.setLoopMode(LoopMode.one);
      
      _audioPlayer.play().catchError((error) {
        print('Error reproduciendo tono de llamada: $error');
      });
    }).catchError((error) {
      print('Error cargando tono de llamada: $error');
    });
  }

  void stopRingtone() {
    if (_audioPlayer.playing) {
      _audioPlayer.stop().catchError((error) {
        print('Error deteniendo tono de llamada: $error');
      }).then((_) {
        print('Tono de llamada detenido.');
      });
    } else {
      print('El tono de llamada no está en reproducción.');
    }
  }

  void _resumeRingtoneIfNeeded() {
    // Lógica para decidir si se debe reanudar el ringtone
    // Aquí puedes añadir condiciones adicionales según tu aplicación
    // Por ejemplo, verificar si otros medios están en pausa o detenidos
    playRingtone();
  }
}
