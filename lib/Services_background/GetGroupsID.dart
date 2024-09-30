import 'package:http/http.dart' as http;
import 'package:segucom_app/Services_background/CacheService.dart';
import 'dart:convert';
import 'dart:async';
import '../configBackend.dart';
import 'package:segucom_app/Services_background/CacheService.dart';

class GroupService {
  final String elementoId;

  GroupService(this.elementoId);

  Future<void> getIDS_Groups() async {
    var url = '${ConfigBackend.backendUrlComunication}/segucomunication/api/groups/getID/$elementoId';
    //print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Q  OBTENIENDO GRUPOS: $url");

    try {
      final response = await http.get(Uri.parse(url));
     // print("@@@@@@@@@@@@@@@@@@@@@@@@@@@  estatu: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Parseamos la respuesta como una lista de enteros
        List<dynamic> data = jsonDecode(response.body);
        List<int> groupIds = data.map((id) => id as int).toList();
        
        // Convertimos la lista de enteros a una cadena separada por comas
        String groupIdsString = groupIds.join(',');

        // Guardamos la cadena en el caché
        await CacheService().saveData('groupsID', groupIdsString);

        // Mostramos los IDs en la consola
      //  print('----------------------------------------------------  IDs de grupos: $groupIds');
        //print('----------------------------------------------------  IDs de grupos (string): $groupIdsString');
      } else {
        print('Error al obtener los IDs de los grupos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al realizar la solicitud GET: $e');
    }
  }
}
