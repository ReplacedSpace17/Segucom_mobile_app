import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:segucom_app/Services_background/CacheService.dart';
import 'package:segucom_app/screens/Home/Home_menu.dart';
import 'package:segucom_app/screens/Message/ChatGruoup.dart';
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
  late Future<List<dynamic>> futureChatsGroups;
  String _numElemento = '';
  String _searchQuery = '';

  List<dynamic> allChats = [];
  List<dynamic> allChatsGroups = [];

  String requestCall = '';
  String requestCallName = '';
  String requestCallNumber = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    getCallerInfo();
    _getrefresh();
    _loadNumElemento().then((_) {
      setState(() {
        futureChats = fetchChats();
        futureChatsGroups = fetchChatsGroups();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  void _getrefresh() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      //validar si hay una solicitud de llamada
    });
  }

//cargar request de llamadas
  // Método para obtener los datos guardados
// Pantalla donde obtienes los datos
  Future<void> getCallerInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? requestCalling = await CacheService().getData('requestCalling');
    String? callerName = await CacheService().getData('callerName');
    String? callerNumber = prefs.getString('callerNumber');

    print("Datos obtenidos:");
    print("requestCalling: $requestCalling");
    print("callerName: $callerName");
    print("callerNumber: $callerNumber");

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
      print(data);
      allChats = data; // Almacenar todos los chats

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

  Future<List<dynamic>> fetchChatsGroups() async {
    if (_numElemento.isEmpty) {
      throw Exception('Número de elemento no cargado');
    }

    final response = await http.get(Uri.parse(
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messagesGroup/$_numElemento'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      allChatsGroups = data; // Almacenar todos los chats de grupo

      return data
          .map((chat) => {
                'ELEMENTO_NUM': chat['ELEMENTO_NUM'],
                'NOMBRE_COMPLETO': chat['GRUPO_DESCRIP'],
                'GRUPO_ID': chat['GRUPO_ID'], // Agregar 'ID_GRUPO
                'ULTIMO_MENSAJE': chat['MENSAJES'].isNotEmpty
                    ? chat['MENSAJES'].last['MENSAJE']
                    : 'No hay mensajes'
              })
          .toList();
    } else {
      throw Exception('Failed to load group chats');
    }
  }

  void _filterChats(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _refreshChats() async {
    setState(() {
      futureChats = fetchChats();
      futureChatsGroups = fetchChatsGroups();
    });
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 350, // Ajusta el ancho según sea necesario
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFDCDCDC)
                      .withOpacity(0.12), // Fondo con 12% de opacidad
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                        color: Colors.black
                            .withOpacity(0.12)), // Contorno con 12% de opacidad
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                        color: Colors.black
                            .withOpacity(0.12)), // Contorno al enfocar
                  ),
                  labelText: 'Buscar',
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0), // Ajustar el padding
                ),
                onChanged: _filterChats,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshChats,
              child: FutureBuilder<List<dynamic>>(
                future: Future.wait([futureChats, futureChatsGroups]),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData ||
                      (snapshot.data![0].isEmpty &&
                          snapshot.data![1].isEmpty)) {
                    return Center(child: Text('No hay chats disponibles'));
                  } else {
                    List<dynamic> chats = snapshot.data![0];
                    List<dynamic> chatsGroups = snapshot.data![1];

                    // Filtrar chats
                    var filteredChats = chats
                        .where((chat) => chat['NOMBRE_COMPLETO']
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();

                    // Filtrar grupos
                    var filteredChatsGroups = chatsGroups
                        .where((chatGroup) => chatGroup['NOMBRE_COMPLETO']
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                        .toList();

                    // Verificar si hay una solicitud de llamada y mover ese chat al principio

                    if (requestCall == 'true') {
                      filteredChats.sort((a, b) {
                        if (a['NOMBRE_COMPLETO'] == requestCallName.toString())
                          return -1; // Mover al principio
                        if (b['NOMBRE_COMPLETO'] == requestCallName)
                          return 1; // Mover al final
                        return 0; // Mantener orden original
                      });
                    }

                    return ListView.builder(
                      itemCount:
                          filteredChats.length + filteredChatsGroups.length,
                      itemBuilder: (context, index) {
                        if (index < filteredChats.length) {
                          var chat = filteredChats[index];
                          bool isRequestCall = requestCall == 'true' &&
                              chat['NOMBRE_COMPLETO'].trim().toLowerCase() ==
                                  requestCallName.trim().toLowerCase();

                          print("Es una solicitud de llamada: $isRequestCall");

                          print("inicio de comparacion de llamad------");
                          print("Nombre del chat de llamada:" +
                              chat['NOMBRE_COMPLETO']);
                          print("Nombre de quién hizo la llamada:" +
                              requestCallName);
                          print("fin de comparacion de llamad------");

                          return Column(
                            children: [
                              Container(
                                color: isRequestCall
                                    ? Colors.blue
                                    : Colors
                                        .transparent, // Color de fondo azul si hay solicitud de llamada
                                child: ListTile(
                                  leading: Image.asset(
                                    'lib/assets/icons/contact.png',
                                    width: 48,
                                    height: 48,
                                  ),
                                  title: Text(
                                    isRequestCall
                                        ? '${chat['NOMBRE_COMPLETO']}'
                                        : '${chat['NOMBRE_COMPLETO']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isRequestCall
                                          ? Colors.white
                                          : Colors
                                              .black, // Cambiar color de texto si hay solicitud de llamada
                                    ),
                                  ),
                                  subtitle: Text(
                                    isRequestCall
                                        ? 'LLAMADA SOLICITADA'
                                        : '${chat['ULTIMO_MENSAJE']}',
                                    style: TextStyle(
                                        color: isRequestCall
                                            ? Colors.white70
                                            : Colors.black54),
                                  ),
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
                                    // Navegar a ChatScreen y esperar resultado
                                    var result =
                                        await Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          chatData: chat,
                                          numElemento: _numElemento,
                                        ),
                                      ),
                                    );

                                    // Actualizar la lista de chats si se envió un mensaje
                                    if (result != null &&
                                        result is bool &&
                                        result) {
                                      setState(() {
                                        futureChats = fetchChats();
                                      });
                                    }
                                  },
                                ),
                              ),
                              Divider(
                                color: Colors.grey,
                                thickness: 1.0,
                                indent: 16.0,
                                endIndent: 16.0,
                              ),
                            ],
                          );
                        } else {
                          var chatGroup =
                              filteredChatsGroups[index - filteredChats.length];
                          return Column(
                            children: [
                              ListTile(
                                leading: Image.asset(
                                  'lib/assets/icons/chatGroup.png',
                                  width: 48,
                                  height: 48,
                                ),
                                title: Text(
                                  '${chatGroup['NOMBRE_COMPLETO']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle:
                                    Text('${chatGroup['ULTIMO_MENSAJE']}'),
                                onTap: () async {
                                  // Navegar a ChatScreenGroup y esperar resultado
                                  var result = await Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreenGroup(
                                        chatData: chatGroup,
                                        numElemento: _numElemento,
                                        idGrupo:
                                            chatGroup['GRUPO_ID'].toString(),
                                      ),
                                    ),
                                  );

                                  // Actualizar la lista de chats si se envió un mensaje
                                  if (result != null &&
                                      result is bool &&
                                      result) {
                                    setState(() {
                                      futureChatsGroups = fetchChatsGroups();
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
                        }
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
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
