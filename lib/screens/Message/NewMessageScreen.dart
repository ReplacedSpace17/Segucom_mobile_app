import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    _futureUsers = fetchUsers();
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(
        Uri.parse('${ConfigBackend.backendUrlComunication}/segucomunication/api/users/80000'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data
          .map((user) => {
                'ELEMENTO_NUMERO': user['ELEMENTO_NUMERO'].toString(), // Asegúrate de convertirlo a String
                'NOMBRE_COMPLETO': '${user['ELEMENTO_NOMBRE']} ${user['ELEMENTO_PATERNO']} ${user['ELEMENTO_MATERNO']}'
              })
          .toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  List<dynamic> _filterUsers(List<dynamic> users, String searchText) {
    if (searchText.isEmpty) {
      return users;
    }

    searchText = searchText.toLowerCase();
    return users.where((user) {
      String nombreCompleto = user['NOMBRE_COMPLETO'].toLowerCase();
      return nombreCompleto.contains(searchText);
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
                labelText: 'Buscar contacto',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _futureUsers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay contactos disponibles'));
                } else {
                  List<dynamic> filteredUsers =
                      _filterUsers(snapshot.data!, _searchText);

                  if (filteredUsers.isEmpty) {
                    return Center(child: Text('No se encontraron resultados'));
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      var user = filteredUsers[index];
                      return ListTile(
                        title: Text('${user['NOMBRE_COMPLETO']}'),
                        onTap: () async {
                          try {
                            // Obtener el chat del usuario seleccionado
                            var chatData =
                                await fetchChatForUser(user['ELEMENTO_NUMERO']);

                            // Navegar a ChatScreen con los datos del chat
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatData: chatData,
                                  numElemento: user['ELEMENTO_NUMERO'],
                                ),
                              ),
                            );
                          } catch (e) {
                            print('Error al obtener chat: $e');
                            // Aquí puedes manejar el error según sea necesario
                          }
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchChatForUser(String elementoNumero) async {
    final response = await http.get(Uri.parse(
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messages/$elementoNumero'));

    if (response.statusCode == 200) {
      dynamic responseData = json.decode(response.body);
      if (responseData is List && responseData.isNotEmpty) {
        // Suponiendo que la API devuelve una lista de mensajes para el usuario,
        // aquí podrías acceder al último mensaje o a cualquier otro dato necesario.
        var lastMessage = responseData.last;
        return {
          'ELEMENTO_NUM': lastMessage['ELEMENTO_NUM'],
          'NOMBRE_COMPLETO': lastMessage['NOMBRE_COMPLETO'],
          'ULTIMO_MENSAJE': lastMessage['MENSAJES'].isNotEmpty
              ? lastMessage['MENSAJES'].last['VALUE']
              : 'No hay mensajes'
        };
      } else {
        throw Exception('No se encontraron mensajes para el usuario $elementoNumero');
      }
    } else {
      throw Exception('Failed to load chat for user $elementoNumero');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
