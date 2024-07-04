import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:segucom_app/screens/Home/Home_menu.dart';
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

class Elemento {
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final int numeroElemento;

  Elemento({
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.numeroElemento,
  });

  factory Elemento.fromJson(Map<String, dynamic> json) {
    return Elemento(
      nombre: json['ELEMENTO_NOMBRE'],
      apellidoPaterno: json['ELEMENTO_PATERNO'],
      apellidoMaterno: json['ELEMENTO_MATERNO'],
      numeroElemento: json['ELEMENTO_NUMERO'],
    );
  }
}

class ScreenScanQR extends StatefulWidget {
  @override
  _ScreenScanQRState createState() => _ScreenScanQRState();
}

class _ScreenScanQRState extends State<ScreenScanQR> {
   List<Elemento> elementos = [];
  List<int> elementosPresentes = []; // Lista de números de elementos presentes
  String qrResult = '';


  @override
  void initState() {
    super.initState();
    _fetchElementosInicial();
    // Agregar inicio de actualización del reloj
  }

  @override
  void dispose() {
  
    super.dispose();
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
             
              SizedBox(height: 10),
              Text(
                'Elementos asigandos',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF073560)),
              ),
             SizedBox(height: 10),
Expanded(
  child: ListView.builder(
    shrinkWrap: true,
    itemCount: elementos.length,
    itemBuilder: (context, index) {
      return _buildCardInformation(
        '${elementos[index].nombre} ${elementos[index].apellidoPaterno} ',
        'Numero de elemento: ' + elementos[index].numeroElemento.toString(),
        'lib/assets/icons/miPerfil.png',
      );
    },
  ),
),


          Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          _scanQR(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1C538E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50), // Adjust the height if needed
        ),
        child: Icon(
          Icons.qr_code,
          color: Colors.white,
        ),
      ),
    ),
          
Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          _cerrarPaseDeLista();
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Color(0xFF073560), backgroundColor: Colors.white, // Text color
          side: BorderSide(color: Color(0xFF073560), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50), // Adjust the height if needed
        ),
        child: Text('Cerrar pase de lista'),
      ),
    ),
          SizedBox(height: 10),
        
            ],
          ),
        ),
      ),
    );
  }

 Future<void> _scanQR(BuildContext context) async {
    try {
      String result = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancelar", true, ScanMode.QR);
      if (result != "-1") {
        // Verificar si el resultado del QR es un número entre 0 y 89999
        int? numeroElemento = int.tryParse(result);
        if (numeroElemento != null && numeroElemento >= 0 && numeroElemento <= 89999) {
          // Verificar si el número de elemento está en la lista de elementos
          if (elementos.any((elemento) => elemento.numeroElemento == numeroElemento)) {
            setState(() {
              qrResult = result;
            });
            _mostrarQRResult(context);
            _actualizarElementosPresentes(numeroElemento);
            _eliminarElemento(numeroElemento);
          } else {
            _mostrarAlerta(context, "El QR no corresponde a un elemento del grupo.");
          }
        } else {
          _mostrarAlerta(context, "El QR escaneado no es válido.");
        }
      }
    } catch (e) {
      _mostrarAlerta(context, "Error al escanear el QR: $e");
    }
  }

  void _actualizarElementosPresentes(int numeroElemento) {
    setState(() {
      if (!elementosPresentes.contains(numeroElemento)) {
        elementosPresentes.add(numeroElemento);
      }
    });
  }

  void _eliminarElemento(int numeroElemento) {
    setState(() {
      elementos.removeWhere((element) => element.numeroElemento == numeroElemento);
    });
  }

  Future<void> _fetchElementos(int idGrupo) async {
    final url = Uri.parse(
        ConfigBackend.backendUrl + '/segucom/api/pase_de_lista/elementos/$idGrupo');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          elementos.clear();
          elementos.addAll(data.map((e) => Elemento.fromJson(e)).toList());
        });
      } else {
        throw Exception('Error al obtener los elementos');
      }
    } catch (e) {
      _mostrarAlerta(context, "Error al obtener los elementos: $e");
    }
  }

  Future<void> _fetchElementosInicial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int grupoID = prefs.getInt('grupoID') ?? 1; // Ejemplo de ID de grupo inicial
      await _fetchElementos(grupoID);
    } catch (e) {
      _mostrarAlerta(
          context, "Error al obtener los elementos al inicio: $e");
    }
  }

  void _mostrarQRResult(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Elemento escaneado'),
          content: Text('Número de elemento: ' + qrResult),
          actions: <Widget>[
            TextButton(
              child: Text('Continuar escaneando'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarAlerta(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(mensaje),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cerrarPaseDeLista() async {
    final prefs = await SharedPreferences.getInstance();
    int grupoID = prefs.getInt('grupoID') ?? 1;
    int idEncabezado = prefs.getInt('ID_Encabezado') ?? 1;

    for (int numeroElemento in elementosPresentes) {
      try {
        final url = Uri.parse(
            ConfigBackend.backendUrl + '/segucom/api/pase_de_lista/validar_elemento/$numeroElemento/$grupoID/$idEncabezado');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          // Lógica adicional si se requiere manejar la respuesta del backend
        } else {
          throw Exception('Error al validar elemento: ${response.statusCode}');
        }
      } catch (e) {
        _mostrarAlerta(context, "Error al validar elemento: $e");
      }
    }

    // Navegar a la pantalla MenuScreen después de cerrar el pase de lista
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MenuScreen()),
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
