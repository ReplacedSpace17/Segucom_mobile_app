import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:segucom_app/configBackend.dart';
import 'package:vibration/vibration.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:segucom_app/screens/Message/screensCalls/VideoCalling.dart';
import 'package:segucom_app/screens/Message/screensCalls/VoiceCalling.dart';
import 'package:segucom_app/main.dart';
import 'package:flutter_sound/flutter_sound.dart';

class CallingService {
  late List<dynamic> messages;
  late TextEditingController messageController;
  final ScrollController _scrollController = ScrollController();
  late IO.Socket socket;
  final ImagePicker _picker = ImagePicker();
  bool isTyping = false;

  // Variables para la grabación de audio
  late FlutterSoundRecorder _recorder;
  late FlutterSoundPlayer _player;
  late FlutterFFmpeg _flutterFFmpeg;
  bool _isRecording = false;
  bool _isPlaying = false;
  late String _filePath;

  // Llamadas
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  List<MediaDeviceInfo> _cameras = [];
  List<MediaDeviceInfo> _microphones = [];
  MediaDeviceInfo? _selectedCamera;
  MediaDeviceInfo? _selectedMicrophone;
  bool _inCall = false;

  final String _callerName;
  final String _callerNumber;
  final String _userElementNumber;

  // Callback para notificar cambios en dispositivos de medios
  final Function(List<MediaDeviceInfo> cameras, List<MediaDeviceInfo> microphones)? onDevicesChanged;

  CallingService({
    required String callerName,
    required String callerNumber,
    required String userElementNumber,
    this.onDevicesChanged,
  })  : _callerName = callerName,
        _callerNumber = callerNumber,
        _userElementNumber = userElementNumber;

  Future<void> initialize() async {
     // Verificar permisos antes de abrir el grabador y el reproductor
  await checkPermissions();
  
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _flutterFFmpeg = FlutterFFmpeg();
    await _recorder.openRecorder();
    await _player.openPlayer();

    Directory tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio_record.aac';

    _socket = IO.io('${ConfigBackend.backendUrlComunication}', <String, dynamic>{
      'transports': ['websocket'],
       'autoConnect': true, // Reconexión automática habilitada
      'reconnection': true,
      'reconnectionAttempts': 10000, // Número de intentos de reconexión
      'reconnectionDelay': 2000, // Retraso entre intentos de reconexión (ms)
    });

    _socket?.on('connect', _onConnect);
    _socket?.on('offer', _onOffer);
    _socket?.on('answer', _onAnswer);
    _socket?.on('candidate', _onCandidate);

    await _initializeRenderers();
    await _requestPermissions();
    await _getMediaDevices();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera.request(),
      Permission.microphone.request(),
    ];
  }

Future<void> checkPermissions() async {
  // Verificar el estado del permiso de cámara
  PermissionStatus cameraStatus = await Permission.camera.status;
  if (cameraStatus.isDenied) {
    print('Permiso de cámara denegado');
  } else if (cameraStatus.isGranted) {
    print('Permiso de cámara concedido');
  } else if (cameraStatus.isPermanentlyDenied) {
    print('Permiso de cámara permanentemente denegado. Solicita al usuario que habilite el permiso en la configuración.');
  }

  // Verificar el estado del permiso de micrófono
  PermissionStatus microphoneStatus = await Permission.microphone.status;
  if (microphoneStatus.isDenied) {
    print('Permiso de micrófono denegado');
  } else if (microphoneStatus.isGranted) {
    print('Permiso de micrófono concedido');
  } else if (microphoneStatus.isPermanentlyDenied) {
    print('Permiso de micrófono permanentemente denegado. Solicita al usuario que habilite el permiso en la configuración.');
  }
}
  Future<void> _getMediaDevices() async {
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      _cameras = devices.where((device) => device.kind == 'videoinput').toList();
      _microphones = devices.where((device) => device.kind == 'audioinput').toList();

      if (_cameras.isNotEmpty) {
        _selectedCamera = _cameras.firstWhere(
          (camera) => camera.label.toLowerCase().contains('front'),
          orElse: () => _cameras[0],
        );
      }

      if (_microphones.isNotEmpty) {
        _selectedMicrophone = _microphones[0];
      }

      // Llamar al callback si está definido
      onDevicesChanged?.call(_cameras, _microphones);
    } catch (e) {
      print('Error enumerating devices: $e');
    }
  }

  void _onConnect(_) {
    print('Connected to server');
    if (_userElementNumber.isNotEmpty) {
      _socket?.emit('setId', _userElementNumber);
    }
  }

  void _onOffer(data) async {
    print("Oferta recibida");
    var description = RTCSessionDescription(data['sdp'], data['type']);
    _showCallDialog(description, data['isVideoCall'], data['callerName'], data['callerNumber']);
  }

  void _onAnswer(data) async {
    var description = RTCSessionDescription(data['sdp'], data['type']);
    await _peerConnection?.setRemoteDescription(description);
  }

  void _onCandidate(data) async {
    var candidate = RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );
    await _peerConnection?.addCandidate(candidate);
  }

  void _showCallDialog(RTCSessionDescription description, bool isVideoCall, String callerName, String callerNumber) async {
    final _audioPlayer = AudioPlayer();
    bool _isRinging = true;

    void playRingtoneAndVibration() {
      _audioPlayer.setAsset('lib/assets/ringtone.mp3').then((_) {
        _audioPlayer.play().catchError((error) {
          print('Error reproduciendo tono de llamada: $error');
        });
      }).catchError((error) {
        print('Error cargando tono de llamada: $error');
      });

      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator == true) {
          Vibration.vibrate(pattern: [500, 1000, 500, 2000]);
        }
      }).catchError((error) {
        print('Error al verificar la vibración: $error');
      });
    }

    showDialog(
      context: SegucomApp.navigatorKey.currentState!.context,
      builder: (BuildContext context) {
        playRingtoneAndVibration();

        return AlertDialog(
          title: const Text('Llamada entrante'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tú tienes una llamada entrante'),
              const SizedBox(height: 8.0),
              if (isVideoCall)
                const Text('Tipo: Videollamada')
              else
                const Text('Tipo: Llamada de voz'),
              const SizedBox(height: 8.0),
              Text('Caller: $callerName'),
              const SizedBox(height: 8.0),
              Text('Number: $callerNumber'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Rechazar'),
              onPressed: () {
                _audioPlayer.stop();
                _isRinging = false;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () async {
                _audioPlayer.stop();
                _isRinging = false;

                await _peerConnection?.setRemoteDescription(description);
                var answer = await _peerConnection?.createAnswer();
                await _peerConnection?.setLocalDescription(answer!);
                _socket?.emit('answer', {
                  'to': _userElementNumber,
                  'sdp': answer?.sdp,
                  'type': answer?.type,
                });

                Navigator.of(context).pop();

                if (isVideoCall) {
                 
                } else {
                  
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _hangUp(BuildContext context) {
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });

    _localStream?.dispose();
    _peerConnection?.close();
    _createPeerConnection();

    Navigator.pop(context);

    _inCall = false;
  }

  Future<void> _createPeerConnection() async {
    await _peerConnection?.close();

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    }, {});

    _peerConnection?.onIceCandidate = (candidate) {
      _socket?.emit('candidate', {
        'to': _userElementNumber,
        'candidate': candidate?.candidate,
        'sdpMid': candidate?.sdpMid,
        'sdpMLineIndex': candidate?.sdpMLineIndex,
      });
    };

    _peerConnection?.onTrack = (event) {
      print('Track received: ${event.track.kind}');
      if (event.track.kind == 'video') {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    _localStream = await _getUserMedia();
    print('Local stream obtained: ${_localStream}');
    _localStream?.getTracks().forEach((track) {
      print('Adding track: ${track.kind}');
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  Future<MediaStream> _getUserMedia() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': _selectedMicrophone != null
            ? {'deviceId': _selectedMicrophone!.deviceId}
            : true,
        'video': _selectedCamera != null
            ? {'deviceId': _selectedCamera!.deviceId}
            : true,
      };
      final mediaStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      if (mediaStream.getTracks().isEmpty) {
        print('No audio or video tracks obtained.');
      } else {
        mediaStream.getTracks().forEach((track) {
          print('Track obtained: ${track.kind}');
        });
      }

      return mediaStream;
    } catch (e) {
      print('Error obtaining media stream: $e');
      throw e;
    }
  }
}
