import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../configBackend.dart';

import 'package:flutter_sound/flutter_sound.dart';

import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';

class ChatScreenGroup extends StatefulWidget {
  //audio

  final Map<String, dynamic> chatData;
  final String numElemento;
  final String idGrupo;
  final List<dynamic> messages; // Nuevo parámetro

  ChatScreenGroup({
    required this.chatData,
    required this.numElemento,
    required this.idGrupo,
    this.messages =
        const [], // Inicializa con una lista vacía si no se pasan mensajes
  });

  @override
  _ChatScreenGroupState createState() => _ChatScreenGroupState();
}

class _ChatScreenGroupState extends State<ChatScreenGroup> {
  List<dynamic> messages = [];
  TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late IO.Socket socket;
  final ImagePicker _picker = ImagePicker();
  bool isTyping = false;
  String NombreRemitente = '';

// Variables para la grabación de audio
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  bool _isRecording = false;
  bool _isPlaying = false;
  String _filePath = '';
bool _isUploading = false; 
String? _thumbnailPath;
double? _lastScrollPosition;
//Map<int, bool> _isPlayingMap = {};
Map<int, bool> _isPlayingMap = {};

Map<int, bool> _isVideoDownloading = {};
Map<int, bool> _isThumbnailGenerating = {};

  /// video
  late VideoPlayerController _videoController;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localVideoPath;

String? _downloadingMessageId;

bool _isSendingVideo = false; // Agrega esta línea

  Future<void> _initialize() async {
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
    super.initState();
    getNameRemitenteGroupChat(widget.numElemento);
    // Si se pasaron mensajes, usarlos directamente
    if (widget.messages.isNotEmpty) {
      setState(() {
        messages = widget.messages; // Asigna los mensajes pasados
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      // Si no se pasaron mensajes, ejecutar fetchMessages
      fetchMessages();
    }

    _initialize(); //inciializar grabador de audio
    socket = IO.io('${ConfigBackend.backendUrlComunication}', <String, dynamic>{
      'transports': ['websocket'],
    });
    socket.on('connect', (_) {
      print('Connected to server');
      // Unir al usuario a un grupo usando widget.idGrupo y widget.numElemento
      if (widget.numElemento.isNotEmpty) {
        socket?.emit('setId', widget.numElemento);
      }

      socket.emit('joinGroup', [widget.idGrupo, widget.numElemento]);
      print('Usuario ${widget.numElemento} unido al grupo ${widget.idGrupo}');
    });
    socket.on('receiveMessage', (data) {
      print('Nuevo mensaje recibido desde servidor: $data');
      _handleReceivedMessage(data);
      
    });

    socket.connect();
    //fetchMessages();
  }

  @override
  void dispose() {
    // Cerrar el grabador y reproductor de audio
    _recorder.closeRecorder();
    _player.closePlayer();

// Liberar el controlador de video si está inicializado
    if (_videoController != null) {
      _videoController!.dispose();
    }

    messageController.dispose();

    super.dispose();
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



 Future<void> _stopPlaying(int messageId) async {
  await _player.stopPlayer();
  setState(() {
    _isPlayingMap[messageId] = false; // Cambiar solo el estado del mensaje actual
  });
}

  /////////////////////////////  obtener nombre
  Future<void> getNameRemitenteGroupChat(String numElemento) async {
    var url =
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messagesGroupWEB/name/$numElemento';

    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var nombreCompleto = responseData['NOMBRE_COMPLETO'];
        NombreRemitente = nombreCompleto;
        print(NombreRemitente);
      } else {
        throw Exception('Failed to fetch remitente name');
      }
    } catch (e) {
      print('Error fetching remitente name: $e');
    }
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
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/audio/groups/${widget.numElemento}/${widget.idGrupo}';

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
          "NOMBRE_REMITENTE": NombreRemitente,
          'ELEMENTO_NUMERO': widget.numElemento,
          'groupId': widget.idGrupo,
          'NOMBRE': NombreRemitente,
          'GRUPO_DESCRIP': widget.chatData['NOMBRE_COMPLETO'],
          'GRUPO_ID': widget.idGrupo,
        };
        print(newMessage);
        socket.emit('sendMessage', newMessage);
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
          '${ConfigBackend.backendUrlComunication}/segucomunication/api/messagesGroup/groupid/${widget.idGrupo}'));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('MENSAJES')) {
          List<dynamic> mensajes = data['MENSAJES'];
          if (mensajes.isNotEmpty) {
            print(mensajes); // Imprime los mensajes obtenidos

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
                    'ELEMENTO_NUMERO': message['ELEMENTO_NUMERO'],
                    'NOMBRE': message['NOMBRE']
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
          throw Exception('Field MENSAJES not found in response');
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  void _handleReceivedMessage(dynamic data) {
    // Verificar si el mensaje pertenece al grupo actual
    if (data['GRUPO_ID'].toString() == widget.idGrupo.toString()) {
      var receivedMessage = {
        'MENSAJE_ID': data['MENSAJE_ID'],
        'FECHA': data['FECHA'],
        'REMITENTE': data['REMITENTE'],
        'MENSAJE': data['MENSAJE'],
        'MEDIA': data['MEDIA'],
        'UBICACION': data['UBICACION'],
        'NOMBRE': data['NOMBRE'],
      };

      // Verificar si el mensaje ya existe en la lista de mensajes
      bool messageExists = messages
          .any((msg) => msg['MENSAJE_ID'] == receivedMessage['MENSAJE_ID']);

      if (!messageExists) {
        if (mounted) {
          setState(() {
            // Ajustar la URL completa del servidor
            if (receivedMessage['MEDIA'] == 'IMAGE') {
              receivedMessage['MENSAJE'] = '${receivedMessage['UBICACION']}';
            }
            if (receivedMessage['MEDIA'] == 'VIDEO') {
              receivedMessage['MENSAJE'] = '${receivedMessage['UBICACION']}';
            }
            messages.add(receivedMessage);
          });

          // Desplazarse al final de la lista de mensajes
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    } else {
      print(
          'Mensaje recibido no pertenece al grupo actual: ${data['GRUPO_ID']}');
    }
  }

  Future<void> sendMessage(String message) async {
    var currentDate = DateTime.now();
    var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDate);

    var requestBody = {
      "FECHA": formattedDate,
      "RECEPTOR": widget.idGrupo,
      "MENSAJE": message,
      "MEDIA": "TXT",
      "UBICACION": "NA",
      "GRUPO_ID": widget.idGrupo
    };

    var url =
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/group/${widget.numElemento}';

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
          'MEDIA': "TXT",
          'UBICACION': "NA",
          'GRUPO_ID': widget.idGrupo,
          'ELEMENTO_NUMERO': widget.numElemento,
          'NOMBRE_REMITENTE': NombreRemitente,
          'groupId': widget.idGrupo,
          'NOMBRE': NombreRemitente,
          'GRUPO_DESCRIP': widget.chatData['NOMBRE_COMPLETO']
        };
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
    var currentDate = DateTime.now();
    var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDate);

    var requestBody = {
      "FECHA": formattedDate,
      "RECEPTOR": widget.idGrupo,
      "MENSAJE": '',
      "MEDIA": filePath,
      "TIPO_MEDIA": fileType,
      "UBICACION": "NA"
    };

    var url =
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/image/group/image/${widget.numElemento}/${widget.idGrupo}';
    print(url);
    try {
      // Convertir el requestBody a formato JSON
      var requestBodyJson = jsonEncode(requestBody);

      // Preparar la solicitud HTTP con la imagen y el requestBody
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      request.fields['data'] =
          requestBodyJson; // Incluir el requestBody como campo

      // Enviar la solicitud y obtener la respuesta
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var imageUrl = responseData[
            'imageUrl']; // Asegúrate de verificar el campo de respuesta

        // Concatenar la URL con el backend

        print(imageUrl);
        var newMessage = {
          'MENSAJE_ID': currentDate.millisecondsSinceEpoch,
          'FECHA': formattedDate,
          'REMITENTE': widget.numElemento,
          'MENSAJE':
              '', // Asegúrate de convertir imageUrl a String si es necesario
          'MEDIA': 'IMAGE',
          
          'UBICACION':
              imageUrl.toString(), // Asegúrate de incluir la URL completa aquí
          'ELEMENTO_NUMERO': widget.numElemento,
          "NOMBRE_REMITENTE": NombreRemitente,
          'groupId': widget.idGrupo,
          'NOMBRE': NombreRemitente,
          'GRUPO_DESCRIP': widget.chatData['NOMBRE_COMPLETO'],
          'GRUPO_ID': widget.idGrupo,
        };
        socket.emit('sendMessage', newMessage);

        if (mounted) {
          setState(() {
            messages.add(newMessage);
          });
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      } else {
        throw Exception('Failed to send media message');
      }
    } catch (e) {
      print('Error sending media message: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _sendMediaMessage(pickedFile.path, 'image');
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      print("######################################    :" + pickedFile.path);
      await _sendMediaMessageVIDEO(pickedFile.path, 'video');
    }
  }

Future<void> _sendMediaMessageVIDEO(String filePath, String fileType) async {
  setState(() {
    _isUploading = true; // Iniciar carga
  });

  var currentDate = DateTime.now();
  var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDate);

  var requestBody = {
    "FECHA": formattedDate,
    "RECEPTOR": widget.idGrupo,
    "MENSAJE": '',
    "MEDIA": filePath,
    "TIPO_MEDIA": fileType,
    "UBICACION": "NA"
  };

  var url =
      '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/video/group/video/${widget.numElemento}/${widget.idGrupo}';
  print(url);

  try {
    var requestBodyJson = jsonEncode(requestBody);

    var request = http.MultipartRequest('POST', Uri.parse(url));
    var file = await http.MultipartFile.fromPath('video', filePath);
    var fileSizeInBytes = file.length; // Tamaño del archivo en bytes
    var fileSizeInMB = fileSizeInBytes / (1024 * 1024); // Convertir a MB

    print(
        "Archivo para enviar: ${file.filename}, tamaño: ${fileSizeInMB.toStringAsFixed(2)} MB");

    request.files.add(file);
    request.fields['data'] = requestBodyJson;

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      var videoUrl = responseData['videoUrl']; // Asegúrate de verificar el campo de respuesta

      var newMessage = {
        'MENSAJE_ID': currentDate.millisecondsSinceEpoch,
        'FECHA': formattedDate,
        'REMITENTE': widget.numElemento,
        'MENSAJE': '',
        'MEDIA': 'VIDEO', // Cambiado de 'IMAGE' a 'VIDEO'
        'UBICACION': videoUrl.toString(),
        'ELEMENTO_NUMERO': widget.numElemento,
        'NOMBRE_REMITENTE': NombreRemitente,
        'groupId': widget.idGrupo,
        'GRUPO_DESCRIP': widget.chatData['NOMBRE_COMPLETO'],
        'GRUPO_ID': widget.idGrupo,
      };

      socket.emit('sendMessage', newMessage);
      print(newMessage);
      if (mounted) {
        setState(() {
          messages.add(newMessage);
          _isUploading = false; // Finalizar carga
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } else {
      print('Error: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to send media message');
    }
  } catch (error) {
    print('Error sending media message: $error');
    setState(() {
      _isUploading = false; // Finalizar carga en caso de error
    });
  }
}

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

Future<Uint8List?> _generateThumbnail(String videoUrl, int messageId) async {
  String thumbnailPath = '${(await getTemporaryDirectory()).path}/${videoUrl.hashCode}.png';

  // Verifica si la miniatura ya existe
  if (await File(thumbnailPath).exists()) {
    print('Miniatura existente encontrada en: $thumbnailPath');
    return await File(thumbnailPath).readAsBytes(); // Devuelve la miniatura almacenada
  }

  print('Intentando generar miniatura para: $videoUrl');
  try {
    final uint8List = await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.PNG,
      maxWidth: 200,
      quality: 75,
    );

    if (uint8List != null) {
      // Guarda la miniatura en el almacenamiento temporal
      await File(thumbnailPath).writeAsBytes(uint8List);
      print('Miniatura generada y guardada en: $thumbnailPath');
    } else {
      print('Miniatura generada es nula. Verifique el video.');
    }
    return uint8List;
  } catch (e) {
    print('Error generando miniatura: $e');
    return null;
  }
}

  Widget _buildMessage(Map<String, dynamic> message) {
    if (message == null) {
      return SizedBox(); // Puedes ajustar esto según lo que desees mostrar para mensajes nulos
    }

    bool isMe = message['REMITENTE'].toString() == widget.numElemento;
    bool isMedia = message.containsKey('MEDIA') && message['MEDIA'] == 'IMAGE';
    bool isAudio = message.containsKey('MEDIA') && message['MEDIA'] == 'AUDIO';
    bool isVideo = message.containsKey('MEDIA') && message['MEDIA'] == 'VIDEO';
    //comprobar si messge contiene MENSAJE_ID
    bool isID = message.containsKey('MENSAJE_ID');
      int messageId = message['MENSAJE_ID'];
      // Inicializa el estado de reproducción si no existe en el mapa
  _isPlayingMap.putIfAbsent(messageId, () => false);
   // print("Contiene ID?: " + isID.toString());
   //  print("######################################################################################################## " + message['MENSAJE_ID'].toString());
    String messageText =
        message['MENSAJE'] ?? ''; // Manejo seguro de mensaje nulo
    String remitente = message['NOMBRE'] ?? '';
    String fecha = message['FECHA'] ?? '';
    //print(message);
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
              child: CachedNetworkImage(
                imageUrl: '${ConfigBackend.backendUrlComunication}${message['UBICACION'] ?? ''}',
                fit: BoxFit.contain,
                width: double.infinity,
                height: 400,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          );
        },
      );
    },
    child: CachedNetworkImage(
      imageUrl: '${ConfigBackend.backendUrlComunication}${message['UBICACION'] ?? ''}',
      width: 200,
      height: 200,
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => Icon(Icons.error),
    ),
  ),

            if (isAudio)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isPlayingMap[messageId]! ? 'Reproduciendo' : 'Mensaje de voz',
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
                      print('REPRODUCIENDO DE: ${ConfigBackend.backendUrlComunication}${message['UBICACION']}');
                      await _player.startPlayer(
                        fromURI: '${ConfigBackend.backendUrlComunication}${message['UBICACION']}',
                        whenFinished: () {
                          setState(() {
                            _isPlayingMap[messageId] = false; // Cambiar el estado del mensaje actual
                          });
                        },
                      );
                      setState(() {
                        _isPlayingMap[messageId] = true; // Cambiar el estado del mensaje actual
                      });
                    }
                  },
                ),
              ],
            ),
   
if (isVideo)
  FutureBuilder<Uint8List?>(
    future: _generateThumbnail('${ConfigBackend.backendUrlComunication}${message['UBICACION'] ?? ''}', message['MENSAJE_ID']),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        // Muestra el texto de carga solo si no se está reproduciendo otro video
        return Center(
          child: Text(
            _isVideoDownloading[message['MENSAJE_ID']] == true
                ? '${(_downloadProgress * 100).toStringAsFixed(0)}% cargando video'
                : _isThumbnailGenerating[message['MENSAJE_ID']] == true
                    ? 'Cargando miniatura...'
                    : 'Miniatura oculta',
            style: TextStyle(color: Colors.white),
          ),
        );
      } else if (snapshot.hasError) {
        return Text('Error al cargar la miniatura');
      } else {
        // Si la miniatura fue generada correctamente, muestra el widget de miniatura
        return GestureDetector(
          onTap: () async {
            // Comienza la descarga del video
            await _downloadVideo('${ConfigBackend.backendUrlComunication}${message['UBICACION'] ?? ''}', message['MENSAJE_ID']);
            // Una vez descargado, reprodúzcalo
            if (_localVideoPath != null) {
              _playVideo(_localVideoPath!);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.memory(
                snapshot.data!,
                width: 200, // Ajusta el ancho de la miniatura
                height: 200, // Ajusta la altura de la miniatura
                fit: BoxFit.cover,
              ),
              Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 64.0, // Tamaño del ícono de reproducción
              ),
              if (_isVideoDownloading[message['MENSAJE_ID']] == true)
                Positioned(
                  bottom: 10,
                  child: Text(
                    '${(_downloadProgress * 100).toStringAsFixed(0)}% cargando video',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      }
    },
  ),



            if (!isMedia && !isAudio && !isVideo)
              Text(
                messageText,
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
            SizedBox(height: 4),
            Text(
              fecha.isNotEmpty
                  ? DateFormat('HH:mm').format(DateTime.parse(fecha))
                  : '',
              style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w400),
            ),
            SizedBox(
                height: 2), // Espacio entre el texto del mensaje y el remitente
            Text(
              remitente,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }



Future<void> _downloadVideo(String url, int messageId) async {
  setState(() {
    _isVideoDownloading[messageId] = true; // Marca el video como en descarga
    _downloadProgress = 0.0;
  });

  try {
    var dir = await getTemporaryDirectory();
    String filePath = '${dir.path}/video_$messageId.mp4';

    await Dio().download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            _downloadProgress = received / total;
          });
        }
      },
    );

    setState(() {
      _localVideoPath = filePath;
      _isVideoDownloading[messageId] = false; // Marca la descarga como completa
    });
    print('Video descargado a: $filePath');
  } catch (e) {
    print('Error al descargar el video: $e');
    setState(() {
      _isVideoDownloading[messageId] = false; // En caso de error, también marcar como completo
    });
  }
}

void _playVideo(String videoPath) {
  _videoController = VideoPlayerController.file(File(videoPath))
    ..setLooping(true) // Omitir si no es necesario
    ..initialize().then((_) {
      // Comienza la reproducción inmediatamente después de inicializar
      _videoController.play();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(controller: _videoController),
      ));
    });
}


Widget _buildDateSeparator(String date) {
  DateTime dateTime = DateTime.parse(date);
  String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime); // Cambia el formato si lo deseas

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
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('lib/assets/icons/contact.png'),
              radius: 20,
            ),
            SizedBox(width: 10),
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
    String prevMessageDate =
        messages[index - 1]['FECHA'].split(' ')[0]; // Extrae solo la fecha
    String currentMessageDate =
        message['FECHA'].split(' ')[0]; // Extrae solo la fecha
    showDateSeparator = prevMessageDate != currentMessageDate; // Compara las fechas
  }

  return Column(
    children: [
      if (showDateSeparator)
        _buildDateSeparator(message['FECHA']), // Mostrar separador solo si es necesario
      _buildMessage(message), // Construir el mensaje
    ],
  );
}

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
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            150.0, // Ajusta este valor según sea necesario
                      ),
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
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.photo),
                                onPressed: _pickImage,
                              ),
                              IconButton(
                                icon: Icon(Icons.video_library),
                                onPressed: _pickVideo,
                              ),
                            ],
                          ),
                        ),
                        maxLines: null, // Permite múltiples líneas
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
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

// Control personalizado para los botones de reproducción
class VideoPlayerControls extends StatelessWidget {
  final VideoPlayerController controller;

  VideoPlayerControls(this.controller);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon:
              Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
      ],
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  FullScreenVideoPlayer({required this.controller});

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  late ValueNotifier<int> _currentPosition;
  late ValueNotifier<int> _totalDuration;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _currentPosition = ValueNotifier<int>(0);
    _totalDuration = ValueNotifier<int>(0);

    _controller.addListener(() {
      if (_controller.value.isInitialized) {
        setState(() {
          _currentPosition.value = _controller.value.position.inSeconds;
          _totalDuration.value = _controller.value.duration.inSeconds;
        });
      }
    });
    _controller.play(); // Inicia la reproducción automáticamente
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            SizedBox(height: 20), // Espacio entre el video y el control
            Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _currentPosition,
                  builder: (context, currentPosition, child) {
                    return Text(
                      '${Duration(seconds: currentPosition).toString().split('.').first}',
                      style: TextStyle(color: Colors.white),
                    );
                  },
                ),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _totalDuration,
                    builder: (context, totalDuration, child) {
                      return Slider(
                        value: _currentPosition.value.toDouble(),
                        min: 0,
                        max: totalDuration.toDouble(),
                        onChanged: (value) {
                          _controller.seekTo(Duration(seconds: value.toInt()));
                        },
                      );
                    },
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _totalDuration,
                  builder: (context, totalDuration, child) {
                    return Text(
                      '${Duration(seconds: totalDuration).toString().split('.').first}',
                      style: TextStyle(color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child:
            Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}