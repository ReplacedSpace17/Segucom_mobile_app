import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:segucom_app/configBackend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UpdateNameScreen extends StatefulWidget {
  final String numeroElemento;

  UpdateNameScreen(this.numeroElemento);

  @override
  _UpdateNameScreenState createState() => _UpdateNameScreenState();
}

class _UpdateNameScreenState extends State<UpdateNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _numElemento = '';

  @override
  void initState() {
    super.initState();
    _loadNumElemento();
  }

  void _loadNumElemento() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _numElemento = prefs.getString('NumeroElemento') ?? '';
    });
  }

  Future<void> _updateName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('NumeroElemento', _numElemento);

    final url = Uri.parse('${ConfigBackend.backendUrl}/segucom/api/user/nombre/$_numElemento');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': _nameController.text}),
    );

    print(url);

    if (response.statusCode == 200) {
      // Mostrar alerta de que se actualizó el nombre
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Nombre actualizado'),
            content: Text('El nombre se ha actualizado correctamente'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Aceptar'),
              ),
            ],
          );
        },
      );
    } else {
      print('Error al actualizar el nombre: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cambiar nombre',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF0B416C),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Número de elemento: $_numElemento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B416C),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nuevo nombre',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre no puede estar vacío';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Color(0xFF0B416C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Lógica para cambiar el nombre
                      await _updateName();
                    }
                  },
                  child: Text(
                    'Actualizar nombre',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
