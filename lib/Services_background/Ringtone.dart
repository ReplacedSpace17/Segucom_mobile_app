import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;

  void playRingtone() {
    _audioPlayer.setAsset('lib/assets/ringtone.mp3').then((_) {
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
}
