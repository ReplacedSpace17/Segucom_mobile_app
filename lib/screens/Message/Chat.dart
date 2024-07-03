import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';
import '../../configBackend.dart';



class ChatScreen extends StatefulWidget {

  //audio
  
  final Map<String, dynamic> chatData;
  final String numElemento;

  ChatScreen({required this.chatData, required this.numElemento});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> messages = [];
  TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late IO.Socket socket;
  final ImagePicker _picker = ImagePicker();
  bool isTyping = false;


// Variables para la grabación de audio
 
  bool _isRecording = false;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    socket = IO.io('${ConfigBackend.backendUrlComunication}', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('receiveMessage', (data) {
      print('Nuevo mensaje recibido desde servidor: $data');
      _handleReceivedMessage(data);
    });

   

    socket.connect();
    fetchMessages();


// Inicializar el grabador de sonido
   

  }

 

  @override
  void dispose() {
    socket.off('receiveMessage', _handleReceivedMessage);
    socket.disconnect();
    messageController.dispose();
    
   
    super.dispose();
  }

//////////////////////// audio
///
// Método para grabar audio
Future<void> _recordAudio() async {
  
}


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

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var audioUrl = responseData['audioUrl'];
        audioUrl = '${ConfigBackend.backendUrlComunication}$audioUrl';
        var newMessage = {
          'MENSAJE_ID': currentDate.millisecondsSinceEpoch,
          'FECHA': formattedDate,
          'REMITENTE': widget.numElemento,
          'MENSAJE': audioUrl.toString(),
          'MEDIA': 'AUDIO',
          'UBICACION': audioUrl.toString(),
        };
        socket.emit('sendMessage', newMessage);
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
        if (mounted) {
          setState(() {
            messages = mensajes.map((message) {
              // Convertir URL de imagen a absoluta si es una imagen
              if (message['MEDIA'] == 'IMAGE') {
                message['MENSAJE'] = '${ConfigBackend.backendUrlComunication}${message['UBICACION']}';
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
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
  var receivedMessage = {
    'MENSAJE_ID': data['MENSAJE_ID'],
    'FECHA': data['FECHA'],
    'REMITENTE': data['REMITENTE'],
    'MENSAJE': data['MENSAJE'],
    'MEDIA': data['MEDIA'],
    'UBICACION': data['UBICACION'],
  };

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
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
        };
        socket.emit('sendMessage', newMessage);
        messageController.clear();
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
    "RECEPTOR": widget.chatData['ELEMENTO_NUM'],
    "MENSAJE": '',
    "MEDIA": filePath,
    "TIPO_MEDIA": fileType,
    "UBICACION": "NA"
  };

  var url =
      '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/image/${widget.numElemento}/${widget.chatData['ELEMENTO_NUM']}';

  try {
    // Convertir el requestBody a formato JSON
    var requestBodyJson = jsonEncode(requestBody);

    // Preparar la solicitud HTTP con la imagen y el requestBody
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('image', filePath));
    request.fields['data'] = requestBodyJson;  // Incluir el requestBody como campo

    // Enviar la solicitud y obtener la respuesta
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      var imageUrl = responseData['imageUrl'];  // Asegúrate de verificar el campo de respuesta
      // Concatenar la URL con el backend
      imageUrl = '${ConfigBackend.backendUrlComunication}$imageUrl';
      var newMessage = {
        'MENSAJE_ID': currentDate.millisecondsSinceEpoch,
        'FECHA': formattedDate,
        'REMITENTE': widget.numElemento,
        'MENSAJE': '',  // Asegúrate de convertir imageUrl a String si es necesario
        'MEDIA': 'IMAGE',
        'UBICACION': imageUrl.toString(),  // Asegúrate de incluir la URL completa aquí
      };
      socket.emit('sendMessage', newMessage);
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
    bool isMe = message['REMITENTE'].toString() == widget.numElemento;
    bool isMedia = message.containsKey('MEDIA') && message['MEDIA'] == 'IMAGE';
    bool isAudio = message.containsKey('MEDIA') && message['MEDIA'] == 'AUDIO';
    String messageText = message['MENSAJE'];

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
                messageText,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            if (isAudio)
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () {
                  // Implementación para reproducir el audio
                },
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
            SizedBox(width: 16),
            Text(
              '${widget.chatData["NOMBRE_COMPLETO"]}',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: () {
              
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () {
             
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(child: Text('No hay mensajes disponibles'))
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
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: IconButton(
                    icon: isTyping ? Icon(Icons.send) : Icon(Icons.mic),
                    onPressed: () {
                      String message = messageController.text.trim();
                      if (message.isNotEmpty) {
                        sendMessage(message);
                      }
                      else {
                        _recordAudio();
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
