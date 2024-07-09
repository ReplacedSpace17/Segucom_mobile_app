import 'package:flutter/material.dart';
import 'package:segucom_app/configBackend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UpdatePasswordScreen extends StatefulWidget {
  final String numeroElemento;

  UpdatePasswordScreen(this.numeroElemento);

  @override
  _UpdatePasswordScreenState createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _numElemento = '';

  @override
  void initState() {
    super.initState();
    _loadNumElemento();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña no puede estar vacía';
    } else if (value.length < 8 || value.length > 12) {
      return 'La contraseña debe tener entre 8 y 12 caracteres';
    } else if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'La contraseña debe tener al menos una letra mayúscula';
    } else if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return 'La contraseña debe tener al menos un número';
    }
    return null;
  }

  void _loadNumElemento() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _numElemento = prefs.getString('NumeroElemento') ?? '';
    });
  }

  Future<void> _updatePassword() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('NumeroElemento', _numElemento);
    final url = Uri.parse(
        // ignore: prefer_interpolation_to_compose_strings
        '${ConfigBackend.backendUrl}/segucom/api/user/' + _numElemento + '/' + _passwordController.text);

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    print(url);
    if (response.statusCode == 200) {
      // alerta de que se actualizo la contraseña, con un show dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Contraseña Actualizada'),
            content: Text('La contraseña se ha actualizado correctamente'),
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
      print('Error al enviar ubicación: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cambiar Contraseña',
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
                'Número de elemento: ${_numElemento}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B416C),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: _validatePassword,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (String? value) {
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
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
                      // Lógica para cambiar la contraseña
                      print('Contraseña cambiada exitosamente');
                      // Mostrar un diálogo de éxito
                      await _updatePassword();
                    }
                  },
                  child: Text(
                    'Actualizar Contraseña',
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
