import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:segucom_app/screens/Message/CallScreen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class MessagesHome extends StatefulWidget {
  @override
  _MessagesHomeState createState() => _MessagesHomeState();
}

class _MessagesHomeState extends State<MessagesHome> {
  String _tel = '';
  List<dynamic> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadTelefono();
  }

  void _loadTelefono() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _tel = prefs.getInt('NumeroTel').toString() ?? '';
      _fetchProfiles();
    });
  }

  Future<void> _fetchProfiles() async {
    if (_tel.isNotEmpty) {
      final url = Uri.parse('http://192.168.1.76:3001/segucomunication/api/users/$_tel');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _profiles = jsonDecode(response.body);
        });
      } else {
        print('Error fetching profiles: ${response.statusCode}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: Color(0xFF073560),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _profiles.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    return _buildProfileCard(profile);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic profile) {
    return ExpansionTile(
      title: Text(
        '${profile["ELEMENTO_NOMBRE"]} ${profile["ELEMENTO_PATERNO"]} ${profile["ELEMENTO_MATERNO"]}',
        style: TextStyle(
          color: Color(0xFF073560),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        profile["ELEMENTO_TELNUMERO"].toString(),
        style: TextStyle(
          color: Color(0xFF2F2F2F),
          fontSize: 14,
        ),
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.message, color: Colors.blue),
              onPressed: () {
                // Acción para mensaje
              },
            ),
            IconButton(
              icon: Icon(Icons.call, color: Colors.green),
              onPressed: () {
               Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          from: _tel,
          to: profile["ELEMENTO_TELNUMERO"].toString(),
        ),
      ),
    );
              },
            ),
            IconButton(
              icon: Icon(Icons.videocam, color: Colors.red),
              onPressed: () {
                // Acción para videollamada
              },
            ),
          ],
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: MessagesHome(),
  ));
}
