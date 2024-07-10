import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../configBackend.dart';
import '../Home/Home_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool showPassword = false;
  bool keepLoggedIn = false;
  int loginAttempts = 0;
  final int maxAttempts = 3;
  final int lockoutDuration = 10; // 5 minutos en segundos 300

  @override
  void initState() {
    super.initState();
    _loadLoginAttempts();
  }

  Future<void> _loadLoginAttempts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loginAttempts = prefs.getInt('loginAttempts') ?? 0;
    });
  }

  Future<void> _incrementLoginAttempts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loginAttempts++;
    });
    await prefs.setInt('loginAttempts', loginAttempts);
    await prefs.setInt(
        'lastAttemptTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _resetLoginAttempts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loginAttempts = 0;
    });
    await prefs.setInt('loginAttempts', loginAttempts);
    await prefs.remove('lastAttemptTime');
  }

  Future<bool> _isLockedOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? lastAttemptTime = prefs.getInt('lastAttemptTime');
    if (lastAttemptTime == null) {
      return false;
    }
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    return currentTime - lastAttemptTime < lockoutDuration * 1000;
  }

 Future<void> _loginUser(String phone, String password) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final url = Uri.parse(ConfigBackend.backendUrl + '/segucom/api/login');
  print('URL: $url');
  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode({
      "telefono": phone,
      "clave": password,
    }),
  );

  if (response.statusCode == 200) {
    // Parsear la respuesta JSON
    final Map<String, dynamic> userData = jsonDecode(response.body);
    print('Datos del usuario: $userData');

    // Guardar el token de autenticación
    final String token = userData['token'];
    prefs.setString('authToken', token);

    // Guardar otros datos del usuario si es necesario
    final String nombre = userData['PERFIL_NOMBRE'];
    final int telefono = userData['ELEMENTO_TELNUMERO'];
    final String elementoNum = userData['ELEMENTO_NUMERO'].toString();
    prefs.setInt('NumeroTel', telefono);
    prefs.setString('Name', nombre);
    prefs.setString('NumeroElemento', elementoNum);

    // Inicio de sesión exitoso
    print('Inicio de sesión exitoso');
    print(nombre);

    // Resetear los intentos fallidos
    await _resetLoginAttempts();

    // Limpiar los campos de texto
    phoneController.clear();
    passwordController.clear();

    // Navegar al menú y pasar los datos del usuario como argumentos
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MenuScreen()),
    );
  } else if (response.statusCode == 403) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Usuario inactivo'),
        duration: Duration(seconds: 3), // Duración del snackbar
        backgroundColor: Colors.red, // Color de fondo del snackbar
      ),
    );
  } else {
    // Incrementar los intentos fallidos
    await _incrementLoginAttempts();
    if (loginAttempts >= maxAttempts) {
      _showErrorSnackBar(
          'Aplicación bloqueada después de 3 intentos fallidos. Espere 5 minutos');
      // Aquí puedes agregar la lógica adicional para bloquear la app
    } else {
      if (response.statusCode == 401) {
        _showErrorSnackBar(
            'Credenciales incorrectas. Intento ${loginAttempts + 1} de $maxAttempts');
      }
    }
  }
}
void _showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _onLoginButtonPressed() async {
    if (await _isLockedOut()) {
      _showErrorSnackBar('Bloqueado. Intente nuevamente más tarde.');
    } else {
      if (keepLoggedIn) {
        // Realizar inicio de sesión
        await _loginUser(phoneController.text, passwordController.text);
      } else {
        // Mostrar un mensaje indicando que el usuario debe mantener la sesión iniciada
        _showErrorSnackBar(
            'Debes mantener la sesión iniciada para iniciar sesión.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: <Widget>[
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'lib/assets/fondoAzul.png',
              fit: BoxFit.cover,
            ),
          ),
          // Contenedor principal con campos de entrada
          Column(
            children: <Widget>[
              // Icono de regresar
              Container(
                margin: EdgeInsets.only(top: 20.0, left: 20.0),
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              // Espacio para el logo
              Container(
                margin: EdgeInsets.only(top: 0.0, bottom: 20.0),
                child: Center(
                  child: Image.asset(
                    'lib/assets/logoBlanco.png',
                    height: 70.0,
                  ),
                ),
              ),
              Spacer(),
              Container(
                height: screenHeight * 0.70,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50.0),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: Text(
                              'Acceso',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B416C),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Campo de teléfono
                          _buildTextField(
                            controller: phoneController,
                            label: 'Número de teléfono',
                            icon: Icons.phone,
                            inputType: TextInputType.phone,
                          ),
                          SizedBox(height: 20),
                          // Campo de contraseña
                          _buildTextField(
                            controller: passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock,
                            obscureText: !showPassword,
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: Text(
                              'Máximo 3 intentos',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Color(0xFF616161),
                              ),
                            ),
                          ),
                          // Checkbox para mantener la sesión iniciada
                          Row(
                            children: [
                              Checkbox(
                                value: keepLoggedIn,
                                onChanged: (bool? value) {
                                  setState(() {
                                    keepLoggedIn = value ?? false;
                                  });
                                },
                                activeColor: Color(0xFF0B416C),
                              ),
                              Text(
                                'Mantener la sesión iniciada',
                                style: TextStyle(
                                  color: Color(0xFF0B416C),
                                ),
                              ),
                            ],
                          ),
                          // Botón de inicio de sesión
                          Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF073560),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                              ),
                              onPressed: _onLoginButtonPressed,
                              child: Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool readOnly = false,
    bool obscureText = false,
    String? text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF0B416C),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller ?? TextEditingController(text: text),
          keyboardType: inputType,
          obscureText: obscureText,
          readOnly: readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: Color.fromARGB(255, 243, 243, 243),
            prefixIcon: Icon(icon, color: Color(0xFF616161)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.0),
              borderSide: BorderSide(color: Color(0xFFD8D8D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.0),
              borderSide: BorderSide(color: Color(0xFF0B416C)),
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: 14.0, horizontal: 14.0),
          ),
        ),
      ],
    );
  }
}
