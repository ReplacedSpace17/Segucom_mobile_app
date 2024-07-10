import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:segucom_app/screens/NotificationsClass/NotificationHome.dart';
import '../configBackend.dart'; // Asegúrate de importar el archivo de configuración adecuado

class UbicationService {
  late Position _currentPosition;
  late DateTime _currentDateTime;

  Future<void> sendLocation(String personalId, String tel, String numElemento) async {
    _currentDateTime = DateTime.now();
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _currentPosition = position;

      if (_currentPosition != null) {
        final url = Uri.parse(
          ConfigBackend.backendUrl + '/segucom/api/maps/elemento/' + tel,
        );
        final body = {
          "PersonalID": personalId,
          "ELEMENTO_LATITUD": _currentPosition.latitude,
          "ELEMENTO_LONGITUD": _currentPosition.longitude,
          "ELEMENTO_ULTIMALOCAL": _currentDateTime.toIso8601String(),
          "Hora": _formatTime(_currentDateTime),
          "Fecha": _formatDate(_currentDateTime),
          "NumTel": tel,
          "ELEMENTO_NUM": numElemento,
        };
        print(body);
        final response = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
        if (response.statusCode == 200) {
          NotificationController.createNewNotification(  "Hola", "Ubicacion enviada");
          print('Ubicación enviada al servidor');
        } else {
          print('Error al enviar ubicación: ${response.statusCode}');
        }
      }
    } catch (e) {
      print("Error al obtener la ubicación: $e");
    }
  }

  String _formatDate(DateTime dateTime) {
    return "${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }
}
