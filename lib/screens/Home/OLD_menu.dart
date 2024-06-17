import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import '../../configBackend.dart';
import './Options/Option1.dart'; // Importa la nueva pantalla WebView
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login_screen.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _personalId = '947e033a-52c1-4fbe-a8d9-50834dae81ba';
  late Position _currentPosition;
  late DateTime _currentDateTime;
  Timer? _timer;
  String _nombre = '';
  String _numElemento = '';
  String _tel = '';

  @override
  void initState() {
    super.initState();
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

  void _startLocationUpdates() {
    _getCurrentLocation();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo de pantalla
          Positioned.fill(
            child: Image.asset(
              'lib/assets/fondoWhite.png',
              fit: BoxFit.cover,
            ),
          ),
          // Botón de cerrar sesión y fecha/hora centrados
          Positioned(
            top: 50.0,
            left: 10.0,
            right: 10.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.logout,
                      color: Color.fromARGB(255, 16, 45, 100)),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
                Column(
                  children: [
                    Text(
                      '${_formatDate(_currentDateTime)}',
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Color.fromARGB(255, 16, 45, 100),
                      ),
                    ),
                    Text(
                      '${_formatTime(_currentDateTime)}',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Color.fromARGB(255, 16, 45, 100),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Contenedor de opciones
          Positioned(
            top: 120.0,
            left: 0,
            right: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 1,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto de saludo
                  Text(
                    'Hi $_nombre!',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Color(0xFF073560),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  // Texto de buenos días
                  Text(
                    'Good Morning',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Color(0xFF787878),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  // Opciones
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    children: [
                      // Card 1
                      _buildCard('Alertamientos', 'lib/assets/icons/alertas.png', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebViewScreen(
                                url:
                                    'https://www.segucom.mx/mobile/grid_ALERTA_MOVIL/?xElemen=$_numElemento', title: 'Alertamientos')
                               
                          ),
                        );
                      }),
                      // Card 2
                      _buildCard('Consignas', 'lib/assets/icons/admin.png', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebViewScreen(
                                url:
                                    'https://www.segucom.mx/mobile/grid_CONSIGNA_MOVIL/?xElemen=$_numElemento', title: 'Consignas'),
                          ),
                        );
                      }),
                      // Card 3
                      _buildCard('QR', 'lib/assets/icons/qr.png', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebViewScreen(
                                url:
                                    'https://www.segucom.mx/mobile/grid_QRElemento/?xElemento=$_numElemento', title: 'QR'),
                          ),
                        );
                      }),
                      // Card 4
                      _buildCard('Notificaciones', 'lib/assets/logo.png', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WebViewScreen(url: 'https://www.segucom.mx/', title: 'Notificaciones'),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String imagePath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0), // Añadimos padding para asegurar espacio dentro de la tarjeta
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 0.5,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF073560),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
