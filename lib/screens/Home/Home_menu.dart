import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import '../../configBackend.dart';
import './Options/Option1.dart'; // Importa la nueva pantalla WebView
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login_screen.dart';
import '../Message/ScreenListChats.dart';
import '../Mi_perfil/ScreenPerfil.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _personalId = '947e033a-52c1-4fbe-a8d9-50834dae81ba';
  late Position _currentPosition;
  late DateTime _currentDateTime;
   late DateTime _currentDateTimeCARD;
  Timer? _timer;
  String _nombre = '';
  String _numElemento = '';
  String _tel = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentDateTime = DateTime.now();
    _startClockUpdates(); // Agregar inicio de actualización del reloj
    _startLocationUpdates();
    _loadNombre();
    _loadTelefono();
    _loadNumElemento();
  }


  void _loadNombre() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('Name') ?? '';
    });
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
        // Navegar a la pantalla de inicio si es necesario
        break;
      case 1:
       Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PerfilScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatListScreen()),
        );
        break;
      case 3:
        // Navegar a la pantalla de ajustes si es necesario
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
              // Saludo
              SizedBox(height: 25),
              Text('Hola,',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(120, 120, 120, 1),
                  )),
              SizedBox(height: 2),
              Text(
                '$_nombre',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(63, 63, 63, 1)),
              ),
              SizedBox(height: 30),
              // Hora y fecha
              Row(
                children: [
                  _buildDateTimeCard(),
                ],
              ),
              SizedBox(height: 30),
              Text(
                'Menú',
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
                    _buildMenuItem(
                      'Boletinaje',
                      '',
                      'lib/assets/icons/alertas.png',
                      Colors.blue,
                      'Descripción de boletinaje',
                      () {
                       Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebViewScreen(
                                url:
                                    'https://www.segucom.mx/mobile/grid_ALERTA_MOVIL/?xElemen=$_numElemento', title: 'Boletinaje')
                               
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 3),
                    _buildMenuItem(
                      'Consignas',
                      '',
                      'lib/assets/icons/admin.png',
                      Colors.green,
                      'Descripción de consignas',
                      () {
                        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => WebViewScreen(
      url: 'https://www.segucom.mx/mobile/grid_CONSIGNA_MOVIL/?xElemen=$_numElemento',
      title: 'Consignas',
    ),
  ),
);

                      },
                    ),
                    SizedBox(height: 3),
                    _buildMenuItem(
                      'Mi QR',
                      '',
                      'lib/assets/icons/qr.png',
                      Colors.orange,
                      'Descripción de mi QR',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebViewScreen(
                              url:
                                  'https://www.segucom.mx/mobile/grid_QRElemento/?xElemento=$_numElemento',
                              title: 'QR',
                            ),
                          ),
                        );
                      },
                    ),
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

  Widget _buildMenuItem(String title, String subtitle, String iconPath,
      Color color, String description, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Color(0xFFDCDCDC)),
      ),
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(
          title,
          style: TextStyle(
            color: Color(0xFF073560),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600]),
              ),
            SizedBox(height: 30), // Espacio entre el título y la descripción
            Text(
              description,
              style: TextStyle(
                color: Color(0xFF2F2F2F),
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: Image.asset(
          iconPath,
          width: 50,
          height: 50,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Container(
      width: MediaQuery.of(context).size.width *
          0.5, // Define el ancho de la card como la mitad de la pantalla
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
                child: Image.asset('lib/assets/icons/clock.png'),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(_currentDateTime),
                    style: TextStyle(
                      color: Color(0xFF073560),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8), // Espacio entre hora y fecha
                  Text(
                    _formatDate(_currentDateTime),
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

