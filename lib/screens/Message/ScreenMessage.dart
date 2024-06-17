import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiUrl = 'http://192.168.1.76:3001/segucomunication/api/messages/80000'; // Endpoint de lista de chats
const String sendMessageUrl = 'http://192.168.1.76:3001/segucomunication/api/messages'; // Endpoint para enviar mensajes

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatListScreen(),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<dynamic>> futureChats;

  @override
  void initState() {
    super.initState();
    futureChats = fetchChats();
  }

  Future<List<dynamic>> fetchChats() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load chats');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureChats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay chats disponibles'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var chat = snapshot.data![index];
                return ListTile(
                  title: Text(
                    'Chat con ${chat['ELEMENTO_NUM']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(chat['MENSAJES'].isNotEmpty
                      ? '${chat['MENSAJES'].last['VALUE']}'
                      : 'No hay mensajes'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chat: chat),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final dynamic chat;

  const ChatScreen({Key? key, required this.chat}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String _numElemento; // Variable para almacenar el número de elemento local
  final TextEditingController _controller = TextEditingController();
  late Future<List<dynamic>> futureMessages;

  @override
  void initState() {
    super.initState();
    _loadNumElemento();
    futureMessages = fetchMessages();
  }

  void _loadNumElemento() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _numElemento = prefs.getString('NumeroElemento') ?? '';
    });
  }

  Future<List<dynamic>> fetchMessages() async {
    final response = await http.get(Uri.parse('$apiUrl/${widget.chat['ELEMENTO_NUM']}'));
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<void> sendMessage(String message) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? _tel = prefs.getString('NumeroTel');

    final response = await http.post(
      Uri.parse('$sendMessageUrl/$_numElemento'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'FECHA': DateTime.now().toString(),
        'RECEPTOR': widget.chat['ELEMENTO_NUM'],
        'MENSAJE': message,
        'MEDIA': 'media_placeholder'
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _controller.clear();
        futureMessages = fetchMessages(); // Recargar los mensajes después de enviar uno nuevo
      });
    } else {
      throw Exception('Failed to send message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${widget.chat['ELEMENTO_NUM']}'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: futureMessages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay mensajes disponibles'));
                } else {
                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var message = snapshot.data![index];
                      bool isMyMessage = message['REMITENTE'] == _numElemento;

                      return Align(
                        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.all(8.0),
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isMyMessage ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['MENSAJE'],
                                style: TextStyle(color: isMyMessage ? Colors.white : Colors.black),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                message['FECHA'],
                                style: TextStyle(fontSize: 12.0, color: isMyMessage ? Colors.white : Colors.black),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
