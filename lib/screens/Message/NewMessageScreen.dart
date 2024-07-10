import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../configBackend.dart';
import './Chat.dart'; // Importar la pantalla ChatScreen

class NewMessageScreen extends StatefulWidget {
  @override
  _NewMessageScreenState createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  late Future<List<dynamic>> _futureUsers;
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String _numElemento = '';

  @override
  void initState() {
    super.initState();
    _loadNumElemento();
  }

  Future<void> _loadNumElemento() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _numElemento = prefs.getString('NumeroElemento') ?? '';
    });
    print(_numElemento);
  }

  Future<List<dynamic>> fetchUsers() async {
    // Asegúrate de que _numElemento esté cargado
    if (_numElemento.isEmpty) {
      await _loadNumElemento();
    }

    final response = await http.get(Uri.parse(
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/users/$_numElemento'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data
          .map((user) => {
                'ELEMENTO_NUMERO': user['ELEMENTO_NUMERO']
                    .toString(), // Asegúrate de convertirlo a String
                'NOMBRE_COMPLETO':
                    '${user['ELEMENTO_NOMBRE']} ${user['ELEMENTO_PATERNO']} ${user['ELEMENTO_MATERNO']}',
                'NUMERO_TELEFONO': user['ELEMENTO_TELNUMERO']
              })
          .toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  List<dynamic> _filterUsers(List<dynamic> users, String searchText) {
    if (searchText.isEmpty || searchText.length < 10) {
      return [];
    }

    searchText = searchText.toLowerCase();
    return users.where((user) {
      print(users);
      print(searchText);
      String telefono = user['NUMERO_TELEFONO'].toString();
      return telefono.contains(searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar contacto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Ingresa el número de teléfono completo',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _searchText.length >= 10
                ? FutureBuilder<List<dynamic>>(
                    future: fetchUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                            child: Text('No hay contactos disponibles'));
                      } else {
                        List<dynamic> filteredUsers =
                            _filterUsers(snapshot.data!, _searchText);

                        if (filteredUsers.isEmpty) {
                          return Center(
                              child: Text('No se encontraron resultados'));
                        }

                        return ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            var user = filteredUsers[index];
                            print(user);
                            return ListTile(
                              title: Text('${user['NOMBRE_COMPLETO']}'),
                              onTap: () async {
                                try {
                                  // Obtener el chat del usuario seleccionado
                                  var chatData = await fetchChatForUser(
                                      user['ELEMENTO_NUMERO']);
                                  print(chatData);
                                  // Navegar a ChatScreen con los datos del chat

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        chatData: chatData,
                                        numElemento:
                                            _numElemento, // Usar el número del usuario actual
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  print('Error al obtener chat: $e');
                                  // En caso de error, aún así navegamos a la pantalla de chat con datos mínimos del usuario
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        chatData: {
                                          'ELEMENTO_NUM':
                                              user['ELEMENTO_NUMERO'],
                                          'NOMBRE_COMPLETO':
                                              user['NOMBRE_COMPLETO'],
                                          'ULTIMO_MENSAJE': 'No hay mensajes'
                                        },
                                        numElemento:
                                            _numElemento, // Usar el número del usuario actual
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      }
                    },
                  )
                : Container(),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchChatForUser(String elementoNumero) async {
    // Intenta obtener los mensajes para el usuario
    final response = await http.get(Uri.parse(
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/$elementoNumero'));

    // Si la respuesta es exitosa y contiene datos, procese los mensajes
    if (response.statusCode == 200) {
      dynamic responseData = json.decode(response.body);
      if (responseData is List && responseData.isNotEmpty) {
        var lastMessage = responseData.last;
        return {
          'ELEMENTO_NUM': elementoNumero,
          'NOMBRE_COMPLETO':
              lastMessage['NOMBRE_COMPLETO'] ?? 'Nueva solicitud',
          'ULTIMO_MENSAJE': lastMessage['MENSAJES'].isNotEmpty
              ? lastMessage['MENSAJES'].last['VALUE']
              : 'No hay mensajes'
        };
      } else {
        // Si no hay mensajes, devuelve el nombre completo del usuario desde el endpoint de usuarios
        return fetchUserInfo(elementoNumero);
      }
    } else {
      throw Exception('Failed to load chat for user $elementoNumero');
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String elementoNumero) async {
    final response = await http.get(Uri.parse(
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/users/$elementoNumero'));

    if (response.statusCode == 200) {
      dynamic userData = json.decode(response.body).firstWhere(
          (user) => user['ELEMENTO_NUMERO'].toString() == elementoNumero,
          orElse: () => null);
      if (userData != null) {
        return {
          'ELEMENTO_NUM': userData['ELEMENTO_NUMERO'],
          'NOMBRE_COMPLETO':
              '${userData['ELEMENTO_NOMBRE']} ${userData['ELEMENTO_PATERNO']} ${userData['ELEMENTO_MATERNO']}',
          'ULTIMO_MENSAJE': 'No hay mensajes'
        };
      } else {
        return {
          'ELEMENTO_NUM': elementoNumero,
          'NOMBRE_COMPLETO': 'Nueva solicitud',
          'ULTIMO_MENSAJE': 'No hay mensajes'
        };
      }
    } else {
      throw Exception('Failed to load user info for $elementoNumero');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
