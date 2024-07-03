import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ScreenScanQR extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear QR'),
      ),
      body: Center(
        child: Container(
          child: ElevatedButton(
            onPressed: () {
              _scanQR(context);
            },
            child: Text('Escanear QR'),
          ),
          
        ),
      ),
      
    );
  }

  Future<void> _scanQR(BuildContext context) async {
    try {
      String qrResult = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancelar", true, ScanMode.QR);
      if (qrResult != "-1") {
        _mostrarAlerta(context, qrResult);
      }
    } catch (e) {
      _mostrarAlerta(context, "Error al escanear el QR: $e");
    }
  }

  void _mostrarAlerta(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resultado del QR'),
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
}

void main() {
  runApp(MaterialApp(
    home: ScreenScanQR(),
  ));
}
