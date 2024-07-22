import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:segucom_app/screens/Home/Home_menu.dart';
import 'package:segucom_app/screens/Home/Options/Option1.dart';
import 'package:segucom_app/screens/Mi_perfil/UpdateName.dart';
import 'dart:convert';
import 'dart:async';
import '../../configBackend.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login_screen.dart';
import '../Message/ScreenListChats.dart';
import 'UpdatePassword.dart'; // Importa la nueva pantalla

class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _personalId = '947e033a-52c1-4fbe-a8d9-50834dae81ba';
  late Position _currentPosition;
  late DateTime _currentDateTime;
  late DateTime _currentDateTimeCARD;
  Timer? _timer;
  String _nombre = '';
  String _numElemento = '';
  String _tel = '';
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _currentDateTime = DateTime.now();
    _startClockUpdates(); // Agregar inicio de actualización del reloj

    _loadNombre();
    _loadTelefono();
    _loadNumElemento();
    _selectedIndex = 1;
  }

  void _loadNombre() async {
    /*
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('Name') ?? '';
    });
    */
final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() async {
      _tel = prefs.getInt('NumeroTel').toString() ?? '';
      final url = Uri.parse(
        ConfigBackend.backendUrl + '/segucom/api/user/personal/' + _tel);
    print(url);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      setState(() {
        _nombre = data['PERFIL_NOMBRE'];
      });
    } else {
      print('Error al obtener el nombre: ${response.statusCode}');
    }
    });
    //hacer una peticion al servidor para obtener el nombre
    
  }

  void _loadNumElemento() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _numElemento = prefs.getString('NumeroElemento') ?? '';
    });
  }

  void _loadTelefono() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _tel = prefs.getInt('NumeroTel').toString() ?? '';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _timer?.cancel(); // Cancelar el timer anterior si existe
    _getCurrentLocation();
    _timer = Timer.periodic(Duration(minutes: 10), (timer) {
      _getCurrentLocation();
      setState(() {
        _currentDateTime = DateTime.now();
      });
    });
  }

  void _startClockUpdates() {
    _timer?.cancel(); // Cancelar el timer anterior si existe
    _getCurrentTime(); // Llamar al método para obtener la hora
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _getCurrentTime(); // Actualizar la hora cada minuto
    });
  }

  void _getCurrentTime() {
    setState(() {
      _currentDateTime = DateTime.now();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _currentPosition = position;
        _currentDateTime = DateTime.now();
      });
      await _sendLocationToServer();
    } catch (e) {
      print("Error al obtener la ubicación: $e");
    }
  }

  Future<void> _sendLocationToServer() async {
    if (_currentPosition != null) {
      final url = Uri.parse(
          ConfigBackend.backendUrl + '/segucom/api/maps/elemento/' + _tel);
      final body = {
        "PersonalID": _personalId,
        "ELEMENTO_LATITUD": _currentPosition.latitude,
        "ELEMENTO_LONGITUD": _currentPosition.longitude,
        "ELEMENTO_ULTIMALOCAL": _currentDateTime.toIso8601String(),
        "Hora": _formatTime(_currentDateTime),
        "Fecha": _formatDate(_currentDateTime),
        "NumTel": _tel,
      };
      print(body);
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        print('Ubicación enviada al servidor');
      } else {
        print('Error al enviar ubicación: ${response.statusCode}');
      }
    }
  }

  String _formatDate(DateTime dateTime) {
    return "${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MenuScreen()),
        );
        break;
      case 1:
        // Navegar a la pantalla de perfil si es necesario
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatListScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WebViewScreen(
                  url: 'https://segucom.mx/help/videos/mobile/',
                  title: 'Menu de ayuda')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container con imagen centrada y texto debajo
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Image.asset(
                      'lib/assets/icons/iconUser.png',
                      width:
                          100, // Puedes ajustar el tamaño de la imagen según sea necesario
                      height: 100,
                    ),
                    SizedBox(height: 20),
                    Text(
                      _nombre,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F3F3F),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 45),
              Text(
                'Información personal',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF073560)),
              ),
              SizedBox(height: 10),
              // Menú
              Expanded(
                child: ListView(
                  children: [
                    _buildCardInformation(
                        'Nombre', _nombre, 'lib/assets/icons/miPerfil.png'),
                    _buildCardInformation('Número elemento', _numElemento,
                        'lib/assets/icons/elemento.png'),
                    _buildCardInformation(
                        'Teléfono', _tel, 'lib/assets/icons/phone.png'),
                    _buildCardInformation('Contraseña', '*********',
                        'lib/assets/icons/password.png'),
                    SizedBox(
                        height:
                            10), // Espacio adicional entre las cards y el botón
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    UpdatePasswordScreen("8088")),
                          );
                        },
                        child: Text('Cambiar Contraseña'),
                      ),
                    ),
                    SizedBox(
                        height:
                            10), // Espacio adicional entre las cards y el botón
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UpdateNameScreen("8088")),
                          );
                        },
                        child: Text('Cambiar Nombre'),
                      ),
                    ),
                    SizedBox(
                        height:
                            10), // Espacio adicional entre las cards y el botón
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        },
                        child: Text('Cerrar Sesión'),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B416C),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Color.fromARGB(255, 255, 255, 255),
          unselectedItemColor: Color.fromARGB(179, 173, 173, 173),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false, // Ocultar etiquetas seleccionadas
          showUnselectedLabels: false, // Ocultar etiquetas no seleccionadas
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_2_outlined),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              label: 'Mensajes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help_outlined),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInformation(String title, String value, String pathIcon) {
    return Container(
      width: MediaQuery.of(context).size.width *
          0.89, // Define el ancho de la card como la mitad de la pantalla
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Color(0xFFDCDCDC)),
        ),
        color: Colors.white,
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFFF5F4F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(pathIcon),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Color(0xFF073560),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 8), // Espacio entre hora y fecha
                  Text(
                    value,
                    style: TextStyle(
                      color: Color(0xFF2F2F2F),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
