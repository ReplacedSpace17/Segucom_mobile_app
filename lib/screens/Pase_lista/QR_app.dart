import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:segucom_app/configBackend.dart';
import 'package:segucom_app/screens/Home/Home_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _fetchElementosInicial(); // Llamar a _fetchElementos al iniciar la pantalla
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear QR'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: elementos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    '${elementos[index].nombre} ${elementos[index].apellidoPaterno} ${elementos[index].apellidoMaterno}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle:
                      Text('Elemento número: ${elementos[index].numeroElemento}'),
                );
              },
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                _scanQR(context);
              },
              child: Text('Escanear QR'),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _cerrarPaseDeLista();
            },
            child: Text('Cerrar pase de lista'),
          ),
        ],
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
            _mostrarAlerta(context, "El QR no corresponde a un elemento válido.");
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
          title: Text('Resultado del escaneo QR'),
          content: Text(qrResult),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
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
              child: Text('OK'),
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
}



void main() {
  runApp(MaterialApp(
    home: ScreenScanQR(),
  ));
}
