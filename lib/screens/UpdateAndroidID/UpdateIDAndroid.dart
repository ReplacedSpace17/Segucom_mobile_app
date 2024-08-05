import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../configBackend.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateAndroidIDScreen extends StatefulWidget {
  @override
  _UpdateAndroidIDScreenState createState() => _UpdateAndroidIDScreenState();
}

class _UpdateAndroidIDScreenState extends State<UpdateAndroidIDScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController elementController = TextEditingController();
  bool showPassword = false;

Future<void> requestPermissions() async {
  await Permission.phone.request();
}

  Future<void> _updateAndroidID() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    //crear un nuevo uidd
     // Genera un UUID
  var uuid = Uuid();
  String uniqueID = uuid.v4(); // Genera un UUID v4
  print(uniqueID);
    final url = Uri.parse(ConfigBackend.backendUrl + '/segucom/api/user/android/updateID');
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "telefono": phoneController.text,
        "clave": passwordController.text,
        "elemento": elementController.text,
        "androidID": uniqueID
      }),
    );

    if (response.statusCode == 200) {
      // Actualización exitosa
       await prefs.setString('AndroidID', uniqueID);
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _showSuccessSnackBar(responseData['message']);
    } else {
      // Manejar errores
      String errorMessage = 'Ocurrió un error. Intente nuevamente.';
      if (response.body.isNotEmpty) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        errorMessage = errorData['error'] ?? errorMessage; 
      }
      _showErrorSnackBar(errorMessage);
    }
  }

  // Función para mostrar un Snackbar con el mensaje de éxito
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Función para mostrar un Snackbar con el mensaje de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Actualizar dispositivo'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Número de teléfono',
              style: TextStyle(color: Color(0xFF0B416C)),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese su número de teléfono',
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Contraseña',
              style: TextStyle(color: Color(0xFF0B416C)),
            ),
            TextField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese su contraseña',
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Número de elemento',
              style: TextStyle(color: Color(0xFF0B416C)),
            ),
            TextField(
              controller: elementController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese su número de elemento',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateAndroidID,
              child: Text('Actualizar dispositivo'),
            ),
          ],
        ),
      ),
    );
  }
}
