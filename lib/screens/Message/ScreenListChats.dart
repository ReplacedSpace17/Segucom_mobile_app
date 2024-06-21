import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../configBackend.dart';
import './Chat.dart'; // Importar la pantalla ChatScreen
import './NewMessageScreen.dart'; // Importar la pantalla NewMessageScreen

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
  String _numElemento = '';

  @override
  void initState() {
    super.initState();
    _loadNumElemento().then((_) {
      setState(() {
        futureChats = fetchChats();
      });
    });
  }

  Future<void> _loadNumElemento() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _numElemento = prefs.getString('NumeroElemento') ?? '';
    });
  }

  Future<List<dynamic>> fetchChats() async {
    if (_numElemento.isEmpty) {
      throw Exception('Número de elemento no cargado');
    }

    final response = await http.get(Uri.parse(
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/$_numElemento'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data
          .map((chat) => {
                'ELEMENTO_NUM': chat['ELEMENTO_NUM'],
                'NOMBRE_COMPLETO': chat['NOMBRE_COMPLETO'],
                'ULTIMO_MENSAJE': chat['MENSAJES'].isNotEmpty
                    ? chat['MENSAJES'].last['VALUE']
                    : 'No hay mensajes'
              })
          .toList();
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
                return Column(
                  children: [
                    ListTile(
                      leading: Image.asset(
                        'lib/assets/icons/contact.png',
                        width: 48,
                        height: 48,
                      ),
                      title: Text(
                        '${chat['NOMBRE_COMPLETO']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${chat['ULTIMO_MENSAJE']}'),
                      onTap: () async {
                        // Navegar a ChatScreen y esperar resultado
                        var result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatData: chat,
                              numElemento: _numElemento, // Pasar _numElemento
                            ),
                          ),
                        );

                        // Verificar si se envió un mensaje desde ChatScreen
                        if (result != null && result is bool && result) {
                          // Actualizar la lista de chats si se envió un mensaje
                          setState(() {
                            futureChats = fetchChats();
                          });
                        }
                      },
                    ),
                    Divider(
                      color: Colors.grey,
                      thickness: 1.0,
                      indent: 16.0,
                      endIndent: 16.0,
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewMessageScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
