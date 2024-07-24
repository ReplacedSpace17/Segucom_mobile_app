import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';
import '../../configBackend.dart';

import 'package:flutter_sound/flutter_sound.dart';

class ChatScreenGroup extends StatefulWidget {
  //audio

  final Map<String, dynamic> chatData;
  final String numElemento;
  final String idGrupo;

  ChatScreenGroup(
      {required this.chatData,
      required this.numElemento,
      required this.idGrupo});

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

  ///

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
    fetchMessages();
  }

  @override
  void dispose() {
    // Cerrar el grabador y reproductor de audio
    _recorder.closeRecorder();
    _player.closePlayer();

    
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

  Future<void> _startPlaying() async {
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
  }

  Future<void> _stopPlaying() async {
    await _player.stopPlayer();
    setState(() {
      _isPlaying = false;
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
          'GRUPO_DESCRIP': widget.chatData['NOMBRE_COMPLETO']


        };
        socket.emit('sendMessage', newMessage);
        if (mounted) {
    setState(() {
      messages.add(newMessage);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
  print('GRUPO_ID: ${data['GRUPO_ID']}');
  print('ID GRUPO: ${widget.idGrupo}');
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
    bool messageExists = messages.any((msg) => msg['MENSAJE_ID'] == receivedMessage['MENSAJE_ID']);

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
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  } else {
    print('Mensaje recibido no pertenece al grupo actual: ${data['GRUPO_ID']}');
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
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
          'NOMBRE': 'XSX',
          'UBICACION':
              imageUrl.toString(), // Asegúrate de incluir la URL completa aquí
              'ELEMENTO_NUMERO': widget.numElemento,
             "NOMBRE_REMITENTE": NombreRemitente,
             'groupId': widget.idGrupo,
             'NOMBRE': NombreRemitente,
             'GRUPO_DESCRIP': widget.chatData['NOMBRE_COMPLETO']

        };
        socket.emit('sendMessage', newMessage);
        if (mounted) {
    setState(() {
      messages.add(newMessage);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    if (message == null) {
      return SizedBox(); // Puedes ajustar esto según lo que desees mostrar para mensajes nulos
    }

    bool isMe = message['REMITENTE'].toString() == widget.numElemento;
    bool isMedia = message.containsKey('MEDIA') && message['MEDIA'] == 'IMAGE';
    bool isAudio = message.containsKey('MEDIA') && message['MEDIA'] == 'AUDIO';
    String messageText =
        message['MENSAJE'] ?? ''; // Manejo seguro de mensaje nulo
    String remitente = message['NOMBRE'] ?? '';
    String fecha = message['FECHA'] ?? '';

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
              Image.network(
                '${ConfigBackend.backendUrlComunication}${message['UBICACION'] ?? ''}',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            if (isAudio)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isPlaying ? 'Reproduciendo' : 'Mensaje de voz',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      color: isMe ? Colors.white : Colors.black,
                    ),
                    onPressed: () async {
                       print(
                            'REPRODUCIENDO DEEE:  ${ConfigBackend.backendUrlComunication}${message['UBICACION'] ?? ''}');
                      if (_isPlaying) {
                        await _stopPlaying();
                      } else {
                        margin:
                        0;
                        await _player.startPlayer(
                          fromURI:
                              '${ConfigBackend.backendUrlComunication}${message['UBICACION'] ?? ''}',
                          whenFinished: () {
                            setState(() {
                              _isPlaying = false;
                            });
                          },
                        );
                        setState(() {
                          _isPlaying = true;
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

  Widget _buildDateSeparator(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          DateFormat('dd/MM/yyyy').format(DateTime.parse(date)),
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
                      showDateSeparator = true;
                    } else {
                      String prevMessageDate =
                          messages[index - 1]['FECHA'].split('T')[0];
                      String currentMessageDate =
                          message['FECHA'].split('T')[0];
                      showDateSeparator =
                          prevMessageDate != currentMessageDate;
                    }

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _buildDateSeparator(message['FECHA']),
                        _buildMessage(message),
                      ],
                    );
                  },
                ),
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
