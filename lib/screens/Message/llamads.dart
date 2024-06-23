import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../configBackend.dart';

class ChatScreen extends StatefulWidget {
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

    socket.on('incomingCall', (data) {
      if (mounted) {
        setState(() {
          String callerName = data['callerName'] ?? 'Desconocido';
          _showIncomingCallAlert(callerName);
        });
      }
    });

    socket.connect();
    fetchMessages();
  }

  @override
  void dispose() {
    socket.off('receiveMessage', _handleReceivedMessage);
    socket.disconnect();
    messageController.dispose();
    super.dispose();
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
              messages = mensajes
                  .map((message) => {
                        'MENSAJE_ID': message['MENSAJE_ID'],
                        'FECHA': message['FECHA'],
                        'REMITENTE': message['REMITENTE'],
                        'MENSAJE': message['MENSAJE'],
                      })
                  .toList();
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
  var receivedMessage = {
    'MENSAJE_ID': data['MENSAJE_ID'],
    'FECHA': data['FECHA'],
    'REMITENTE': data['REMITENTE'],
    'MENSAJE': data['MENSAJE'],
  };

  // Verificar si el mensaje recibido es de tipo llamada
  if (_isCallMessage(receivedMessage) && receivedMessage['REMITENTE'] != widget.numElemento) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Llamada entrante'),
            content: Text('Tienes una llamada entrante'),
            actions: [
              TextButton(
                child: Text('Aceptar'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _acceptCall();
                },
              ),
              TextButton(
                child: Text('Rechazar'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _rejectCall();
                },
              ),
            ],
          );
        },
      );
    }
  }
}


bool _isCallMessage(Map<String, dynamic> message) {
  // Define tu lógica específica para determinar si el mensaje es de tipo llamada
  // Aquí asumo que el mensaje de llamada tiene un formato específico en el campo 'MENSAJE'
  return message['MENSAJE'] == 'r=1 applyTransaction=true mTimestamp=37050635613438(auto) mPendingTransactions.size=0 graphicBufferId=80324478369800 transform=0';
}



  Future<void> sendMessage(String message) async {
    var currentDate = DateTime.now();
    var formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDate);

    var requestBody = {
      "FECHA": formattedDate,
      "RECEPTOR": widget.chatData['ELEMENTO_NUM'],
      "MENSAJE": message,
      "MEDIA": ""
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

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isMe = message['REMITENTE'].toString() == widget.numElemento;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
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
            Text(
              message['MENSAJE'],
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            SizedBox(height: 5),
            Text(
              DateFormat('HH:mm').format(DateTime.parse(message['FECHA'])),
              style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black54, fontSize: 12),
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
              _initiateCall();
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () {
              _initiateCall(isVideo: true);
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
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    String message = messageController.text.trim();
                    if (message.isNotEmpty) {
                      sendMessage(message);
                    }
                  },
                  child: Text('Enviar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showIncomingCallAlert(String callerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Llamada entrante'),
          content: Text('Tienes una llamada entrante de $callerName'),
          actions: [
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
                _acceptCall();
              },
            ),
            TextButton(
              child: Text('Rechazar'),
              onPressed: () {
                Navigator.of(context).pop();
                _rejectCall();
              },
            ),
          ],
        );
      },
    );
  }

  void _initiateCall({bool isVideo = false}) {
    print('Iniciando llamada...');

    // Preparamos los datos del mensaje de llamada
    var callMessage = {
      'MENSAJE_ID': DateTime.now().millisecondsSinceEpoch,
      'FECHA': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'REMITENTE': widget.numElemento,
      'MENSAJE': 'r=1 applyTransaction=true mTimestamp=37050635613438(auto) mPendingTransactions.size=0 graphicBufferId=80324478369800 transform=0',
    };

    // Emitimos el mensaje de llamada vía Socket.IO
    socket.emit('sendMessage', callMessage);
  }

  void _acceptCall() {
    // Lógica para aceptar la llamada
  }

  void _rejectCall() {
    // Lógica para rechazar la llamada
  }
}
