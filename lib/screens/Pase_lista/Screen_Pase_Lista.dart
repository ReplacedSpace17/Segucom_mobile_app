import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:segucom_app/screens/Pase_lista/QR_app.dart';
import 'package:segucom_app/screens/Pase_lista/Screen_Pase_Lista.dart';
import 'dart:convert';
import 'dart:async';
import '../../configBackend.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login_screen.dart';
import '../Message/ScreenListChats.dart';
import '../Mi_perfil/ScreenPerfil.dart';

class ScreenPaseLista extends StatefulWidget {
  @override
  _ScreenPaseListaState createState() => _ScreenPaseListaState();
}

class _ScreenPaseListaState extends State<ScreenPaseLista> {
  late DateTime _currentDateTime;
  Timer? _timer;
  int _idGrupo = 0;
  @override
  void initState() {
    super.initState();
    _currentDateTime = DateTime.now();
    _startClockUpdates(); // Agregar inicio de actualización del reloj
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startClockUpdates() {
    _timer?.cancel(); // Cancelar el timer anterior si existe
    _getCurrentTime(); // Llamar al método para obtener la hora
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _getCurrentTime(); // Actualizar la hora cada segundo
    });
  }

  //metodo para cargar el id del grupo
  Future<int> cargarIdGrupo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int idGrupo = prefs.getInt('grupoID')!;
    return idGrupo;
  }

  Future<int> cargarNumeroElemento() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String idGrupoSTR = prefs.getString('NumeroElemento')!;
    int idGrupo = int.parse(idGrupoSTR);
    return idGrupo;
  }

  void _getCurrentTime() {
    setState(() {
      _currentDateTime = DateTime.now();
    });
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a')
        .format(dateTime); // Formato 12 horas sin segundos
  }

  Future _IniciarPaseLista(
      BuildContext context, String numeroElemento, String idGrupo) async {
    // Mostrar Snackbar de "Verificando permisos"
    final verifyingSnackBar = SnackBar(
      content: Text('Iniciando pase de lista...'),
      duration:
          Duration(days: 1), // Duración larga hasta que se esconda manualmente
    );
    ScaffoldMessenger.of(context).showSnackBar(verifyingSnackBar);

    final url = Uri.parse(ConfigBackend.backendUrl +
        '/segucom/api/pase_de_lista/encabezado/' +
        numeroElemento.toString() +
        '/' +
        idGrupo.toString());
    final response = await http.post(url);
    // Ocultar Snackbar de "Verificando permisos"
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (response.statusCode == 400) {
      //mostrar un mensaje de que no tiene permisos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Ya existe un pase de lista para este grupo y por el mismo elemento el mismo día'),
        ),
      );
    } else {
      if (response.statusCode == 200) {
        //obtener el cuerpo de la respuesta
        final body = jsonDecode(response.body);
        final EncabezadoID = body['PASENCA_ID'];
        //guardar con shared preferences el grupoID
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt('ID_Encabezado', EncabezadoID);
        print("Encabezado : " + EncabezadoID.toString());
        //enviar a la pantalla de pase de lista ScreenPaseLista()
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ScreenScanQR()),
        );
      }
      else{
 ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se ha podido iniciar el pase de lista'),
        ),
      );
      }
    }
/*
    
   else {
      //mostrar un mensaje de que no tiene permisos
     
    }

    */
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
              SizedBox(height: 15),
              Text('Bienvenido/a al',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(120, 120, 120, 1),
                  )),
              SizedBox(height: 2),
              Text(
                'Pase de Lista',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(63, 63, 63, 1)),
              ),
              SizedBox(height: 20),
              // Hora y fecha
              Row(
                children: [
                  _buildDateTimeCard(),
                ],
              ),
              SizedBox(height: 10),
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
                      'Iniciar Pase de Lista',
                      '',
                      'lib/assets/icons/iconPaseLista.png',
                      Colors.blue,
                      'Selecciona para comenzar',
                      () async {
                        // Instancia de shared preferences
                        final prefs = await SharedPreferences.getInstance();

                        // Obtener el numero de elemento, manejar null
                        String? numeroElemento =
                            prefs.getString('NumeroElemento');
                        if (numeroElemento == null) {
                          // Manejar caso de null, tal vez mostrar un mensaje o usar un valor por defecto
                          print("Numero de elemento no encontrado");
                          return;
                        }

                        // Obtener el id del grupo, manejar null
                        int? idGrupo = prefs.getInt('grupoID');
                        if (idGrupo == null) {
                          // Manejar caso de null, tal vez mostrar un mensaje o usar un valor por defecto
                          print("ID del grupo no encontrado");
                          return;
                        }

                        // Imprimir ambos
                        print("Numero de elemento: $numeroElemento");
                        print("ID del grupo: $idGrupo");
                        print("Iniciar pase de lista");

                        // Iniciar pase de lista
                        _IniciarPaseLista(
                            context, idGrupo.toString(), numeroElemento);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
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
