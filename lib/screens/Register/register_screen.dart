import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Login/login_screen.dart';
import '../../configBackend.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController employeeNumberController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String imei = '';
  bool showPassword = false;
  bool acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _getDeviceDetails();
  }

  Future<void> _getDeviceDetails() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    setState(() {
      imei = androidInfo.id;
    });
  }

  Future<void> _registerUser(Map<String, dynamic> user) async {
    final url = Uri.parse(ConfigBackend.backendUrl + '/segucom/api/user');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(user),
    );

    if (response.statusCode == 200) {
      // Registro exitoso
      print('Usuario registrado correctamente');

      // Limpiar los campos de texto
      employeeNumberController.clear();
      nameController.clear();
      phoneController.clear();
      passwordController.clear();

      // Ir al login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      // Error en el registro
      print('Error en el registro: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true, // Importante para evitar problemas de teclado
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
                margin: EdgeInsets.only(top: 40.0, left: 20.0),
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Spacer(),
              Container(
                height: screenHeight * 0.88,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50.0),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16.0),
                      child: Padding( // Agrega Padding para ajustar el ancho
                        padding: EdgeInsets.symmetric(horizontal: 20.0), // Ajusta este valor según sea necesario
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Center(
                              child: Text(
                                'Registro',
                                style: TextStyle(
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0B416C),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            // Campo de número de empleado
                            _buildTextField(
                              controller: employeeNumberController,
                              label: 'Número de elemento',
                              icon: Icons.badge,
                              inputType: TextInputType.number,
                            ),
                            SizedBox(height: 15), // Espacio reducido
                            // Campo de nombre
                            _buildTextField(
                              controller: nameController,
                              label: 'Ingresa tú nombre',
                              icon: Icons.person,
                            ),
                            SizedBox(height: 15), // Espacio reducido
                            // Campo de teléfono
                            _buildTextField(
                              controller: phoneController,
                              label: 'Ingresa tú número de teléfono',
                              icon: Icons.phone,
                              inputType: TextInputType.phone,
                            ),
                            SizedBox(height: 15), // Espacio reducido
                            // Campo de contraseña
                            _buildTextField(
                              controller: passwordController,
                              label: 'Crea una contraseña',
                              icon: Icons.lock,
                              obscureText: !showPassword,
                            ),
                            SizedBox(height: 15), // Espacio reducido
                            Center(
                              child: Text(
                                'La clave debe contener mínimo 8 y máximo 12 caracteres, una letra mayúscula, un número.',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Color(0xFF616161),
                                ),
                              ),
                            ),
                            SizedBox(height: 15), // Espacio reducido
                            // Checkbox para mostrar la contraseña
                            Row(
                              children: [
                                Checkbox(
                                  value: showPassword,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      showPassword = value ?? false;
                                    });
                                  },
                                  activeColor: Color(0xFF0B416C),
                                ),
                                Text(
                                  'Mostrar contraseña',
                                  style: TextStyle(
                                    color: Color(0xFF0B416C),
                                  ),
                                ),
                              ],
                            ),
                            // Checkbox para aceptar términos y condiciones
                            Row(
                              children: [
                                Checkbox(
                                  value: acceptTerms,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      acceptTerms = value ?? false;
                                    });
                                  },
                                  activeColor: Color(0xFF0B416C),
                                ),
                                Text(
                                  'Acepto los términos y condiciones',
                                  style: TextStyle(
                                    color: Color(0xFF0B416C),
                                  ),
                                ),
                              ],
                            ),
                            // Botón de registro
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF073560), // Color de fondo
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                ),
                                onPressed: acceptTerms
                                    ? () {
                                        var user = {
                                          "No_Empleado": int.tryParse(employeeNumberController.text) ?? 0,
                                          "Nombre": nameController.text,
                                          "Telefono": phoneController.text,
                                          "IMEI": imei,
                                          "Clave": passwordController.text
                                        };
                                        _registerUser(user);
                                      }
                                    : null,
                                child: Text(
                                  'CREAR CUENTA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w300, // Letra light
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
            fontWeight: FontWeight.w400,
            fontSize: 14.0,
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0), // Padding personalizado
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.0),
              borderSide: BorderSide(color: Color(0xFFD8D8D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11.0),
              borderSide: BorderSide(color: Color(0xFF0B416C)),
            ),
          ),
        ),
      ],
    );
  }
}
