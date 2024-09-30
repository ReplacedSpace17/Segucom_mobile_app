import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:segucom_app/Services_background/CacheService.dart';
import 'package:segucom_app/Services_background/MessagesService.dart';
import 'package:segucom_app/screens/Home/Home_menu.dart';
import 'package:segucom_app/screens/Message/ChatGruoup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../configBackend.dart';
import './Chat.dart';
import './NewMessageScreen.dart';

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
  late Future<void> _initFuture;

  List<dynamic> allChats = [];
  List<dynamic> allChatsGroups = [];

  String _numElemento = '';
  String _searchQuery = '';

  String requestCall = '';
  String requestCallName = '';
  String requestCallNumber = '';
  Timer? _timer;
  String messageNotRead = '';

  List<String> chatsWithNewMessages = [];

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
    _startPeriodicChatUpdate();
  }

  Future<void> _initialize() async {
    await getCallerInfo();
    await _loadNumElemento();
    try {
      allChats = await fetchChats();
      allChatsGroups = await fetchChatsGroups();
      setState(() {});
    } catch (e) {
      print('Error al cargar los chats o grupos: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPeriodicChatUpdate() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        List<String> newChatsWithMessages = [];
        List<String> newChatsWithMessagesGroups = [];

        for (var chat in allChats) {
          String nombreCompleto = chat['NOMBRE_COMPLETO'].toString().replaceAll(' ', '');
          String? isNewMessage = await CacheService().getData(nombreCompleto);
          if (isNewMessage == 'true') {
            newChatsWithMessages.add(nombreCompleto);
          }
        }

        for (var chatGroup in allChatsGroups) {
          String nombreCompleto = chatGroup['NOMBRE_COMPLETO'].toString().replaceAll(' ', '');
          String? isNewMessage = await CacheService().getData(nombreCompleto);
          if (isNewMessage == 'true') {
            newChatsWithMessagesGroups.add(nombreCompleto);
          }
        }

        // Actualizar el estado solo si hay cambios en los mensajes nuevos
        if (!listEquals(chatsWithNewMessages, newChatsWithMessages) ||
            !listEquals(chatsWithNewMessages, newChatsWithMessagesGroups)) {
          setState(() {
            chatsWithNewMessages = newChatsWithMessages;
            chatsWithNewMessages.addAll(newChatsWithMessagesGroups);
          });
        }
      } catch (e) {
        print('Error al actualizar los chats: $e');
      }
    });
  }


  Future<void> getCallerInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? requestCalling = await CacheService().getData('requestCalling');
    String? callerName = await CacheService().getData('callerName');
    String? callerNumber = prefs.getString('callerNumber');

    print("Datos obtenidos:");
    print("requestCalling: $requestCalling");
    print("callerName: $callerName");
    print("callerNumber: $callerNumber");

    //final MessageService messageService = MessageService(_numElemento.toString());

    if (requestCalling == 'true') {
      requestCallName = callerName!;
      print("Hay llamadas en curso pendientes");
      setState(() {
        requestCall =
            'true'; // Actualiza el estado a 'true' si hay una llamada en curso
        requestCallName =
            callerName ?? 'no se pudo obtener'; // Nombre del llamador
        requestCallNumber = callerNumber ?? ''; // Número del llamador
      });

      print('Nombre del llamador: $requestCallName');
      print('Número del llamador: $requestCallNumber');
    } else {
      print('No hay llamadas en curso');
    }
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
      return data.map((chat) => {
                'ELEMENTO_NUM': chat['ELEMENTO_NUM'],
                'NOMBRE_COMPLETO': chat['NOMBRE_COMPLETO'],
                'ULTIMO_MENSAJE': chat['MENSAJES'].isNotEmpty
                    ? chat['MENSAJES'].last['VALUE']
                    : 'No hay mensajes'
              }).toList();
    } else {
      throw Exception('Failed to load chats');
    }
  }

  Future<List<dynamic>> fetchChatsGroups() async {
    if (_numElemento.isEmpty) {
      throw Exception('Número de elemento no cargado');
    }

    final response = await http.get(Uri.parse(
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messagesGroup/$_numElemento'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((chat) => {
                'ELEMENTO_NUM': chat['ELEMENTO_NUM'],
                'NOMBRE_COMPLETO': chat['GRUPO_DESCRIP'],
                'GRUPO_ID': chat['GRUPO_ID'],
                'ULTIMO_MENSAJE': chat['MENSAJES'].isNotEmpty
                    ? chat['MENSAJES'].last['MENSAJE']
                    : 'No hay mensajes'
              }).toList();
    } else {
      throw Exception('Failed to load group chats');
    }
  }

  Future<void> _refreshChats() async {
    try {
      allChats = await fetchChats();
      allChatsGroups = await fetchChatsGroups();
      setState(() {});
    } catch (e) {
      print('Error al refrescar los chats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen()),
            );
          },
        ),
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            // Filtrar chats
            var filteredChats = allChats
                .where((chat) => chat['NOMBRE_COMPLETO']
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
                .toList();

            // Filtrar grupos
            var filteredChatsGroups = allChatsGroups
                .where((chatGroup) => chatGroup['NOMBRE_COMPLETO']
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
                .toList();

            // Verificar si hay una solicitud de llamada y mover ese chat al principio
            if (requestCall == 'true') {
              filteredChats.sort((a, b) {
                if (a['NOMBRE_COMPLETO'] == requestCallName.toString())
                  return -1;
                if (b['NOMBRE_COMPLETO'] == requestCallName)
                  return 1;
                return 0;
              });
            }

            return RefreshIndicator(
              onRefresh: _refreshChats,
              child: ListView.builder(
                itemCount: filteredChats.length + filteredChatsGroups.length,
                itemBuilder: (context, index) {
                  final Key itemKey = ValueKey(index);

                  if (index < filteredChats.length) {
                    var chat = filteredChats[index];
                    bool isRequestCall = requestCall == 'true' &&
                        chat['NOMBRE_COMPLETO'].trim().toLowerCase() ==
                            requestCallName.trim().toLowerCase();

                    bool hasUnreadMessages = chatsWithNewMessages
                        .contains(chat['NOMBRE_COMPLETO'].toString().replaceAll(' ', ''));

                    return Column(
                      key: itemKey,
                      children: [
                        ListTile(
                          tileColor: isRequestCall ? Colors.blue.shade50 : null,
                          leading: Icon(
                            Icons.person,
                            color: isRequestCall ? Colors.blue : null,
                          ),
                          title: Text(chat['NOMBRE_COMPLETO']),
                           subtitle: Text(
                hasUnreadMessages
                    ? 'Mensajes nuevos...'
                    : isRequestCall
                        ? 'LLAMADA SOLICITADA'
                        : chat['ULTIMO_MENSAJE'],
                style: TextStyle(
                    color: isRequestCall
                        ? const Color.fromARGB(179, 0, 0, 0)
                        : hasUnreadMessages
                            ? const Color.fromARGB(255, 0, 0, 0) // Texto negro si hay mensajes no leídos
                            : Colors.black54),
              ),
                          trailing: hasUnreadMessages
                              ? Icon(Icons.notification_important, color: Colors.red)
                              : null,
                          onTap: () async {
                            final String? elementoLLamante =
                                        await CacheService()
                                            .getData('elementoLLamante');
                                    print("Valor de elementoLLamante: $elementoLLamante");
                                    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ -elemento chat: ${chat['ELEMENTO_NUM']}");

                                   
                                    if (elementoLLamante.toString() ==
                                        chat['ELEMENTO_NUM'].toString()) {
                                           await CacheService()
                                        .saveData('ringtoneKey', 'false');
                                    await CacheService()
                                        .saveData('requestCalling', 'false');
                                      print(
                                          "|@@··~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  Navegando a ChatListScreen, valor de ringtone: FALSE");
                                    }

                String chatElementoNum = chat['NOMBRE_COMPLETO'].toString().replaceAll(' ', '');

                if (chatsWithNewMessages.contains(chatElementoNum)) {
                  print('Se eliminan los mensajes no leídos para $chatElementoNum');
                  await CacheService().saveData(chatElementoNum, 'false');
                }

             

                var result = await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatData: chat,
                      numElemento: _numElemento,
                    ),
                  ),
                );

              
                          },
                        ),
                        Divider(),
                      ],
                    );
                  } else {
                    var chatGroup = filteredChatsGroups[index - filteredChats.length];
                    bool hasUnreadMessagesGroup = chatsWithNewMessages
                        .contains(chatGroup['NOMBRE_COMPLETO'].toString().replaceAll(' ', ''));

                    return Column(
                      key: itemKey,
                      children: [
                        ListTile(
                          leading: Icon(Icons.group),
                          title: Text(chatGroup['NOMBRE_COMPLETO']),
                          subtitle: Text(
                hasUnreadMessagesGroup
                    ? 'Mensajes nuevos...'
                    : chatGroup['ULTIMO_MENSAJE'].length > 10
                        ? chatGroup['ULTIMO_MENSAJE'].substring(0, 10) + '…'
                        : chatGroup['ULTIMO_MENSAJE'],
                style: TextStyle(
                    color: hasUnreadMessagesGroup
                        ? const Color.fromARGB(255, 0, 0, 0) // Texto negro si hay mensajes no leídos
                        : Colors.black54),
              ),
                          trailing: hasUnreadMessagesGroup
                              ? Icon(Icons.notification_important, color: Colors.red)
                              : null,
                          onTap: () async {

                 final String? elementoLLamante =
                    await CacheService().getData('elementoLLamante');

                String chatElementoNum = chatGroup['NOMBRE_COMPLETO'].toString().replaceAll(' ', '');

                if (chatsWithNewMessages.contains(chatElementoNum)) {
                  print('Se eliminan los mensajes no leídos para $chatElementoNum');
                  await CacheService().saveData(chatElementoNum, 'false');
                }
                var result = await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreenGroup(
                      chatData: chatGroup,
                      numElemento: _numElemento,
                      idGrupo: chatGroup['GRUPO_ID'].toString(),
                    ),
                  ),
                );

               
                          },
                        ),
                        Divider(),
                      ],
                    );
                  }
                },
              ),
            );
          }
        },
      ),
    );
  }
}
