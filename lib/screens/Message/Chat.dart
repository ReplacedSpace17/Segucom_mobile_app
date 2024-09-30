import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:segucom_app/Services_background/MessagesService.dart';
import 'package:segucom_app/Services_background/Ringtone.dart';
import 'package:segucom_app/main.dart';
import 'package:segucom_app/screens/Message/ScreenListChats.dart';
import 'package:segucom_app/screens/Message/screensCalls/VideoCalling.dart';
import 'package:segucom_app/screens/Message/screensCalls/VoiceCalling.dart';
import 'package:segucom_app/screens/NotificationsClass/NotificationHome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';
import '../../configBackend.dart';

import 'package:flutter_sound/flutter_sound.dart';

class ChatScreen extends StatefulWidget {
  //audio
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  final Map<String, dynamic> chatData;
  final String numElemento;

  ChatScreen({required this.chatData, required this.numElemento});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isDisponibility = false;
  List<dynamic> messages = [];
  TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late IO.Socket socket;
  final ImagePicker _picker = ImagePicker();
  bool isTyping = false;

// Variables para la grabación de audio
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  bool _isRecording = false;
  bool _isPlaying = false;
  String _filePath = '';
  bool _isUploading = false; // Variable para controlar el estado de carga

  Map<int, bool> _isPlayingMap = {};

//llamadas
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  List<MediaDeviceInfo> _cameras = [];
  List<MediaDeviceInfo> _microphones = [];
  MediaDeviceInfo? _selectedCamera;
  MediaDeviceInfo? _selectedMicrophone;
  bool _inCall = false;

  List<dynamic> DATA_Chat_Fetch = [];

  Timer? _timer;

  ///
  ///
  String _callerName = "Usuario";
  String _callerNumber = "477";
  bool _isDialogShowing = false; // Variable para controlar si el diálogo está visible


  Future<void> _initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('requestCalling', 'false');

    await _recorder.openRecorder();
    await _player.openPlayer();

    if (await Permission.microphone.request().isGranted) {
      // Permiso concedido
    } else {
      // Permiso denegado
    }

    Directory tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio_record.aac';
  }

  @override
   void initState() {
    //load nombre y numero
    _loadNombre();
    _loadTelefono();
    super.initState();
    _FinalizedRingtone();
    _initialize(); //inciializar grabador de audio
    _connectSocket();
    socket = IO.io('${ConfigBackend.backendUrlComunication}', <String, dynamic>{
      'transports': ['websocket'],
    });
    print(
        "Conectando INIT.................................................................................");
    _socket?.emit('joinChat', {
      'userId1': widget.numElemento,
      'userId2': widget.chatData['ELEMENTO_NUM'],
    });
    socket.on('receiveMessage', (data) {
      print('Nuevo mensaje recibido desde chat: $data');
      _handleReceivedMessage(data);
    });

    socket.connect();
    fetchMessages();

    _requestPermissions();
    _initializeRenderers();

    _createPeerConnection();
    _getMediaDevices();
    _checkDisponibilityPeriodically();
    
  }

  void _FinalizedRingtone() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('ringtone', false);
    print("Estableciendo llamada en false");
  }

  void _loadNombre() async {

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _callerName = prefs.getString('NombreBD') ?? '';
      prefs.setBool('ringtone', false);
    });

    prefs.setString('requestCalling', 'false');

    // final MessageService messageService = MessageService(widget.numElemento.toString());

  }

  void _loadTelefono() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _callerNumber = prefs.getInt('NumeroTel').toString() ?? '';
    });
  }

  @override
  void dispose() {
    _socket?.emit('leaveChat', {
      'userId': widget.numElemento, // Asegúrate de pasar el ID del usuario
      'chatId': widget.chatData['ELEMENTO_NUM'], // El ID de la sala de chat
    });
    // Cerrar el grabador y reproductor de audio
    _recorder.closeRecorder();
    _player.closePlayer();

    // socket.off('receiveMessage', _handleReceivedMessage);
    //socket.disconnect();
    messageController.dispose();

    /// llamadas
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    _peerConnection?.dispose();
    _timer?.cancel();
    super.dispose();
  }

//////////////////////////////////////// llamadas

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  void _connectSocket() {
    print(
        "Conectando socket.................................................................................");
    _socket =
        IO.io('${ConfigBackend.backendUrlComunication}', <String, dynamic>{
      'transports': ['websocket'],
    });

    _socket?.on('connect', (_) {
      print(
          "CONECTADO socket.................................................................................");
      print('connected');
      if (widget.numElemento.isNotEmpty) {
        _socket?.emit('setId', widget.numElemento);

// Emitir el evento joinChat con un mapa
        if (_socket?.connected ?? false) {
        } else {
          print('Socket no está conectado');
        }
      }

      print(
          "#########################################################3  UserId1: ${widget.numElemento}");
      print(
          "########################################################## UserId2: ${widget.chatData['ELEMENTO_NUM']}");
    });

    _socket?.on('offer', (data) async {
      print("Oferta recibida");
      var description = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection?.setRemoteDescription(description);

    if (!_isDialogShowing) { // Verifica si ya hay un diálogo visible
    _isDialogShowing = true; // Marca el diálogo como visible
    
    // Muestra el diálogo
    _showCallDialog(description, data['isVideoCall'], data['callerName'], data['callerNumber']);
    
    // Aquí puedes restablecer la variable cuando se cierre el diálogo.
    // Supongamos que `_showCallDialog` es una función que llama a `showDialog`.
    // En el callback del botón de aceptación o cancelación del diálogo, debes asegurarte
    // de establecer `_isDialogShowing = false` manualmente.
  }
    });

    _socket?.on('answer', (data) async {
      var description = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection?.setRemoteDescription(description);
    });

    _socket?.on('candidate', (data) async {
      var candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
    });
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
        'to': widget.chatData['ELEMENTO_NUM'],
        'candidate': candidate?.candidate,
        'sdpMid': candidate?.sdpMid,
        'sdpMLineIndex': candidate?.sdpMLineIndex,
      });
    };

    _peerConnection?.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    _localStream = await _getUserMedia();
    _localStream!.getTracks().forEach((track) {
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
      return await navigator.mediaDevices.getUserMedia(mediaConstraints);
    } catch (e) {
      print('Error getting user media: $e');
      throw e;
    }
  }

  void _getMediaDevices() async {
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      setState(() {
        _cameras =
            devices.where((device) => device.kind == 'videoinput').toList();
        _microphones =
            devices.where((device) => device.kind == 'audioinput').toList();
        if (_cameras.isNotEmpty) {
          _selectedCamera = _cameras.firstWhere(
            (camera) => camera.label.toLowerCase().contains('front'),
            orElse: () => _cameras[0],
          );
        }
        if (_microphones.isNotEmpty) {
          _selectedMicrophone = _microphones[0];
        }
      });
    } catch (e) {
      print('Error enumerating devices: $e');
    }
  }

// ----------------------------------------------------------------------------- function para comprobar disponibilidad de llamadas
  Future<int> checkDisponibility(String me, String destinatario) async {
    var url =
        '${ConfigBackend.backendUrlComunication}/check-chatroom-status/$me/$destinatario';
  print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ chat: " + url);
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

  Future<void> sendRequestCallUser(
      String me, String destinatario, bool videoCall, String nombre) async {
    var url = '${ConfigBackend.backendUrlComunication}/test-call-request/';

    var callData = {
      'from': me,
      'type': videoCall ? 'video' : 'voice',
      'callerName': nombre,
      'to': destinatario,
    };

    print(callData);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(callData),
      );
    } catch (e) {
      print('Error al enviar la solicitud: $e');
    }
  }

  void _checkDisponibilityPeriodically() {
    // Ejecuta la función cada segundo
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) async {
      var response = await checkDisponibility(
        widget.numElemento.toString(),
        widget.chatData['ELEMENTO_NUM'].toString(),
      );
      if (response == 200) {
        setState(() {
          isDisponibility = response == 200;
        });
      }
      if (response == 400) {
        setState(() {
          isDisponibility = response == 200;
        });
      }
      print(response.toString());
      print('isDisponibility: $isDisponibility');
    });
  }

  void _startCall() async {
    //llamar a la funcion para comprobar disponibilidad
    var response = await checkDisponibility(widget.numElemento.toString(),
        widget.chatData['ELEMENTO_NUM'].toString());
    print(response.toString());
    //validar si la respuesta es 200 para poder realizar la llamada de lo contrario mostrar un dialogo
    if (response == 200) {
      try {
        var offer =
            await _peerConnection?.createOffer({'offerToReceiveVideo': true});
        await _peerConnection?.setLocalDescription(offer!);
        _socket?.emit('offer', {
          'to': widget.chatData['ELEMENTO_NUM'],
          'sdp': offer?.sdp,
          'type': offer?.type,
          'isVideoCall': true,
          'callerName': _callerName,
          'callerNumber': _callerNumber,
          'me': widget.numElemento
        });
        setState(() {
          _inCall = true;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenCalling(
              localRenderer: _localRenderer,
              remoteRenderer: _remoteRenderer,
              onHangUp: _hangUp,
              callerName: _callerName,
              callerNumber: _callerNumber,
                 me: widget.numElemento.toString(),
      destinatario: widget.chatData['ELEMENTO_NUM'].toString(),
            ),
          ),
        );
      } catch (e) {
        print('Error starting video call: $e');
      }
      print("Usuarios disponibles para llamada");
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Llamada no disponible'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'El usuario no está disponible para recibir llamadas en este momento, ¿desea enviar una solicitud?'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                },
              ),
              TextButton(
                child: const Text('Sí'),
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo

                  // Llamar a la función para enviar la solicitud

                  sendRequestCallUser(
                      widget.numElemento.toString(),
                      widget.chatData['ELEMENTO_NUM'].toString(),
                      true,
                      _callerName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitud enviada correctamente'),
                    ),
                  );

                  // Aquí puedes agregar la lógica para enviar la solicitud
                },
              ),
            ],
          );
        },
      );
    }
    /*
  
    */
  }

  void _startVoiceCall() async {
    //llamar a la funcion para comprobar disponibilidad
    var response = await checkDisponibility(widget.numElemento.toString(),
        widget.chatData['ELEMENTO_NUM'].toString());
    print(response.toString());
    //validar si la respuesta es 200 para poder realizar la llamada de lo contrario mostrar un dialogo
    if (response == 200) {
      try {
        var offer =
            await _peerConnection?.createOffer({'offerToReceiveVideo': false});
        await _peerConnection?.setLocalDescription(offer!);
        _socket?.emit('offer', {
          'to': widget.chatData['ELEMENTO_NUM'],
          'sdp': offer?.sdp,
          'type': offer?.type,
          'isVideoCall': false,
          'callerName': _callerName,
          'callerNumber': _callerNumber,
          'me': widget.numElemento
        });
        setState(() {
          _inCall = true;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenVoiceCalling(
              localRenderer: _localRenderer,
              remoteRenderer: _remoteRenderer,
              onHangUp: _hangUp,
              callerName: _callerName,
              callerNumber: _callerNumber,
              incomingStream:
                  null,
                   me: widget.numElemento.toString(),
      destinatario: widget.chatData['ELEMENTO_NUM'].toString(),
            ),
          ),
        );
      } catch (e) {
        print('Error starting voice call: $e');
      }
      print("Usuarios disponibles para llamada");
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Llamada no disponible'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'El usuario no está disponible para recibir llamadas en este momento, ¿desea enviar una solicitud?'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                },
              ),
              TextButton(
                child: const Text('Sí'),
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo

                  // Llamar a la función para enviar la solicitud

                  sendRequestCallUser(
                      widget.numElemento.toString(),
                      widget.chatData['ELEMENTO_NUM'].toString(),
                      false,
                      _callerName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitud enviada correctamente'),
                    ),
                  );

                  // Aquí puedes agregar la lógica para enviar la solicitud
                },
              ),
            ],
          );
        },
      );
    }
    /*
   
    */
  }

 Future<void> _hangUp() async {
  // Detener las pistas y limpiar la conexión
  _localStream?.getTracks().forEach((track) {
    track.stop();
  });

  _localStream?.dispose();
  _peerConnection?.close();
  _createPeerConnection();

  // Primero ejecuta Navigator.pop
  Navigator.pop(context);

  // Luego espera un breve momento antes de realizar la siguiente navegación
  await Future.delayed(const Duration(milliseconds: 1000));

  // Ahora ejecuta Navigator.pushReplacement
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => ChatListScreen()),
  );

  /*
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => ScreenListChats(
        numElemento: widget.numElemento,
      ),
    ),
  );
  */

  // Cambiar el estado de la llamada
  setState(() {
    _inCall = false;
  });

  // Cerrar la aplicación (si es necesario)
  /*
  if (Platform.isAndroid || Platform.isIOS) {
    // Cierra la aplicación
    exit(0);
  }
  */
}


  void _showCallDialog(RTCSessionDescription description, bool isVideoCall,
      String callerName, String callerNumber) async {
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
    if (isDisponibility) {
      _isDialogShowing = false;
      _audioPlayer.stop();
      _isRinging = false;

      await _peerConnection?.setRemoteDescription(description);
      var answer = await _peerConnection?.createAnswer();
      await _peerConnection?.setLocalDescription(answer!);
      _socket?.emit('answer', {
        'to': widget.chatData['ELEMENTO_NUM'],
        'sdp': answer?.sdp,
        'type': answer?.type,
      });

      Navigator.of(context).pop();

      if (isVideoCall) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenCalling(
              localRenderer: _localRenderer,
              remoteRenderer: _remoteRenderer,
              onHangUp: _hangUp,
              callerName: callerName,
              callerNumber: callerNumber,
              me: widget.numElemento.toString(),
              destinatario: widget.chatData['ELEMENTO_NUM'].toString(),
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScreenVoiceCalling(
              localRenderer: _localRenderer,
              remoteRenderer: _remoteRenderer,
              onHangUp: _hangUp,
              callerName: callerName,
              callerNumber: callerNumber,
              incomingStream: null,
              me: widget.numElemento.toString(),
              destinatario: widget.chatData['ELEMENTO_NUM'].toString(),
            ),
          ),
        );
      }
    } else {
      
      Navigator.of(context).pop();
      _isDialogShowing = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La llamada ha finalizado.'),
        ),
      );
    }
  },
),
 ],
        );
      },
    );

    Future.delayed(const Duration(seconds: 30), () {
      if (_isRinging) {
        _audioPlayer.stop();
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  void _switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!
          .getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      await Helper.switchCamera(videoTrack);
    }
  }

  void _muteMic() async {
    if (_localStream != null) {
      final audioTrack = _localStream!
          .getAudioTracks()
          .firstWhere((track) => track.kind == 'audio');
      final enabled = audioTrack.enabled;
      audioTrack.enabled = !enabled;
    }
  }

//////////////////////// audio
  Future<void> _startRecording() async {
    await _recorder.startRecorder(toFile: _filePath);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    await _sendAudioMessage(_filePath);
  }

  Future<void> _startPlaying() async {
    try {
      await _player.startPlayer(
          fromURI: _filePath,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
            });
          });
      print("LINK DE AUDIO:" + _filePath);
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print('Error starting player: $e');
    }
  }

  Future<void> _stopPlaying(int messageId) async {
    await _player.stopPlayer();
    setState(() {
      _isPlayingMap[messageId] =
          false; // Cambiar solo el estado del mensaje actual
    });
  }

////////////////////////

  // Método para enviar el mensaje de audio
  Future<void> _sendAudioMessage(String filePath) async {
    var currentDate = DateTime.now();
    var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDate);

    var requestBody = {
      "FECHA": formattedDate,
      "RECEPTOR": widget.chatData['ELEMENTO_NUM'],
      "MENSAJE": '',
      "MEDIA": filePath,
      "TIPO_MEDIA": "AUDIO",
    };

    var url =
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/audio/${widget.numElemento}/${widget.chatData['ELEMENTO_NUM']}';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('audio', filePath));
      request.fields['FECHA'] = formattedDate;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var audioUrl = responseData['audioUrl'];

        var newMessage = {
          'MENSAJE_ID': currentDate.millisecondsSinceEpoch,
          'FECHA': formattedDate,
          'REMITENTE': widget.numElemento,
          'MENSAJE': audioUrl.toString(),
          'MEDIA': 'AUDIO',
          'UBICACION': audioUrl.toString(),
          'to': widget.chatData['ELEMENTO_NUM'],
          'NOMBRE': widget.chatData['NOMBRE_COMPLETO']
        };
        socket.emit('sendMessage', newMessage);
        // Agregar el mensaje enviado a la lista messages
        if (mounted) {
          setState(() {
            messages.add(newMessage);
          });
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      } else {
        throw Exception('Failed to send audio message');
      }
    } catch (e) {
      print('Error sending audio message: $e');
    }
  }

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(Uri.parse(
          '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/${widget.numElemento}/${widget.chatData['ELEMENTO_NUM']}'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          List<dynamic> mensajes = data[0]['MENSAJES'];
          print(mensajes);
          DATA_Chat_Fetch = data;
          if (mounted) {
            setState(() {
              messages = mensajes.map((message) {
                // Convertir URL de imagen a absoluta si es una imagen
                if (message['MEDIA'] == 'IMAGE') {
                  message['MENSAJE'] =
                      '${ConfigBackend.backendUrlComunication}${message['UBICACION']}';
                }
                return {
                  'MENSAJE_ID': message['MENSAJE_ID'],
                  'FECHA': message['FECHA'],
                  'REMITENTE': message['REMITENTE'],
                  'MENSAJE': message['MENSAJE'],
                  'MEDIA': message['MEDIA'],
                  'UBICACION': message['UBICACION'],
                };
              }).toList();
            });
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToBottom());
          }
        } else {
          if (mounted) {
            setState(() {
              messages = [];
            });
          }
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  void _handleReceivedMessage(dynamic data) {
    // Verificar si el mensaje pertenece al grupo actual y el remitente es el correcto
    //imprimir el to y el numElemento
    print('To: ${data['to']}');
    print('NumElemento: ${widget.numElemento}');
    if (data['to'].toString() == widget.numElemento.toString()) {
      NotificationController.createNewNotification(
          "Mensaje recibido ", "De: " + data['NOMBRE']);
      var receivedMessage = {
        'MENSAJE_ID': data['MENSAJE_ID'],
        'FECHA': data['FECHA'],
        'REMITENTE': data['REMITENTE'],
        'MENSAJE': data['MENSAJE'],
        'MEDIA': data['MEDIA'],
        'UBICACION': data['UBICACION'],
      };

      // Verificar si el mensaje ya existe en la lista de mensajes
      bool messageExists = messages
          .any((msg) => msg['MENSAJE_ID'] == receivedMessage['MENSAJE_ID']);

      if (!messageExists) {
        if (mounted) {
          setState(() {
            if (receivedMessage['MEDIA'] == 'IMAGE') {
              // Ajustar la URL completa del servidor
              receivedMessage['MENSAJE'] = '${receivedMessage['UBICACION']}';
            }
            messages.add(receivedMessage);
          });
          // Desplazarse al final de la lista de mensajes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Desplazarse solo si aún está montado
              _scrollToBottom();
            }
          });
        }
      }
    } else {
      print(
          'Mensaje recibido no pertenece al grupo actual o el remitente no coincide: Grupo ID ${data['GRUPO_ID']} y Remitente ${data['REMITENTE']}');
    }
  }

  Future<void> sendMessage(String message) async {
    var currentDate = DateTime.now();
    var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDate);

    var requestBody = {
      "FECHA": formattedDate,
      "RECEPTOR": widget.chatData['ELEMENTO_NUM'],
      "MENSAJE": message,
      "MEDIA": "TXT",
      "UBICACION": "NA"
    };

    var url =
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/${widget.numElemento}';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        var newMessage = {
          'MENSAJE_ID': currentDate.millisecondsSinceEpoch,
          'FECHA': formattedDate,
          'REMITENTE': widget.numElemento,
          'MENSAJE': message,
          'MEDIA': 'TXT',
          'UBICACION': 'NA',
          'to': widget.chatData['ELEMENTO_NUM'],
          'NOMBRE': _callerName
        };
        print(newMessage);
        socket.emit('sendMessage', newMessage);
        messageController.clear();

        // Agregar el mensaje enviado a la lista messages
        if (mounted) {
          setState(() {
            messages.add(newMessage);
          });
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _sendMediaMessage(String filePath, String fileType) async {
    setState(() {
      _isUploading = true; // Iniciar carga
    });

    var currentDate = DateTime.now();
    var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDate);

    var requestBody = {
      "FECHA": formattedDate,
      "RECEPTOR": widget.chatData['ELEMENTO_NUM'],
      "MENSAJE": '',
      "MEDIA": filePath,
      "TIPO_MEDIA": fileType,
      "UBICACION": "NA"
    };

    var url =
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/image/${widget.numElemento}/${widget.chatData['ELEMENTO_NUM']}';

    try {
      var requestBodyJson = jsonEncode(requestBody);
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      request.fields['data'] = requestBodyJson;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var imageUrl = responseData['imageUrl'];

        print(imageUrl);
        var newMessage = {
          'MENSAJE_ID': currentDate.millisecondsSinceEpoch,
          'FECHA': formattedDate,
          'REMITENTE': widget.numElemento,
          'MENSAJE': '',
          'MEDIA': 'IMAGE',
          'UBICACION': imageUrl.toString(),
          'to': widget.chatData['ELEMENTO_NUM'],
          'NOMBRE': _callerName
        };
        socket.emit('sendMessage', newMessage);
        if (mounted) {
          setState(() {
            messages.add(newMessage);
            _isUploading = false; // Finalizar carga
          });
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      } else {
        throw Exception('Failed to send media message');
      }
    } catch (e) {
      print('Error sending media message: $e');
      setState(() {
        _isUploading = false; // Finalizar carga en caso de error
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _sendMediaMessage(pickedFile.path, 'image');
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isMe = message['REMITENTE'].toString() == widget.numElemento;
    bool isMedia = message.containsKey('MEDIA') && message['MEDIA'] == 'IMAGE';
    bool isAudio = message.containsKey('MEDIA') && message['MEDIA'] == 'AUDIO';
    String messageText = message['MENSAJE'];
    int messageId = message['MENSAJE_ID'];

    // Inicializa el estado de reproducción si no existe en el mapa
    _isPlayingMap.putIfAbsent(messageId, () => false);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: isMe
              ? BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                )
              : BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                  topLeft: Radius.circular(10),
                ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isMedia)
              GestureDetector(
                onTap: () {
                  // Mostrar la imagen en una vista emergente
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: InteractiveViewer(
                          child: Image.network(
                            '${ConfigBackend.backendUrlComunication}${message['UBICACION']}',
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 400,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Image.network(
                  '${ConfigBackend.backendUrlComunication}${message['UBICACION']}',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (isAudio)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isPlayingMap[messageId]!
                          ? 'Reproduciendo'
                          : 'Mensaje de voz',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlayingMap[messageId]! ? Icons.stop : Icons.play_arrow,
                      color: isMe ? Colors.white : Colors.black,
                    ),
                    onPressed: () async {
                      if (_isPlayingMap[messageId]!) {
                        await _stopPlaying(messageId);
                      } else {
                        // Reproducir el audio
                        print(
                            'REPRODUCIENDO DE: ${ConfigBackend.backendUrlComunication}${message['UBICACION']}');
                        await _player.startPlayer(
                          fromURI:
                              '${ConfigBackend.backendUrlComunication}${message['UBICACION']}',
                          whenFinished: () {
                            setState(() {
                              _isPlayingMap[messageId] =
                                  false; // Cambiar el estado del mensaje actual
                            });
                          },
                        );
                        setState(() {
                          _isPlayingMap[messageId] =
                              true; // Cambiar el estado del mensaje actual
                        });
                      }
                    },
                  ),
                ],
              ),
            if (!isMedia && !isAudio)
              Text(
                messageText,
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
            SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(DateTime.parse(message['FECHA'])),
              style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(String date) {
    DateTime dateTime = DateTime.parse(date);
    String formattedDate = DateFormat('dd/MM/yyyy')
        .format(dateTime); // Cambia el formato si lo deseas

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          formattedDate,
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Elimina la flecha de retroceso por defecto
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back), // Flecha de retroceso
              onPressed: () {
                  
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ChatListScreen()),
                );
              },
            ),
            CircleAvatar(
              backgroundImage: AssetImage('lib/assets/icons/contact.png'),
              radius: 20,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                '${widget.chatData["NOMBRE_COMPLETO"]}',
                style: TextStyle(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone),
            color: isDisponibility ? Colors.green : Colors.grey,
            onPressed: _startVoiceCall, // Este método siempre se puede ejecutar
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            color: isDisponibility ? Colors.green : Colors.grey,
            onPressed: _startCall, // Este método siempre se puede ejecutar
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(child: Text('Aún no hay mensajes, envía el primero!'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      bool showDateSeparator = false;

                      if (index == 0) {
                        // Muestra el separador para el primer mensaje
                        showDateSeparator = true;
                      } else {
                        String prevMessageDate = messages[index - 1]['FECHA']
                            .split(' ')[0]; // Extrae solo la fecha
                        String currentMessageDate = message['FECHA']
                            .split(' ')[0]; // Extrae solo la fecha
                        showDateSeparator = prevMessageDate !=
                            currentMessageDate; // Compara las fechas
                      }

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _buildDateSeparator(message[
                                'FECHA']), // Mostrar separador solo si es necesario
                          _buildMessage(message), // Construir el mensaje
                        ],
                      );
                    },
                  ),
          ),
          if (_isUploading) // Muestra el loader si está subiendo
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onChanged: (value) {
                      setState(() {
                        isTyping = value.trim().isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide(
                          color: Color.fromARGB(
                              255, 17, 55, 95), // Color del borde
                          width: 2.0, // Ancho del borde
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 15.0),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: _pickImage,
                      ),
                    ),
                    maxLines: null, // Permite múltiples líneas
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: IconButton(
                    icon: _isRecording
                        ? Icon(Icons.stop)
                        : (isTyping ? Icon(Icons.send) : Icon(Icons.mic)),
                    onPressed: () {
                      if (isTyping) {
                        String message = messageController.text.trim();
                        if (message.isNotEmpty) {
                          sendMessage(message);
                        }
                      } else {
                        if (_isRecording) {
                          _stopRecording();
                        } else {
                          _startRecording();
                        }
                      }
                    },
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}