import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:segucom_app/screens/NotificationsClass/NotificationHome.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:segucom_app/configBackend.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vibration/vibration.dart';

class MessageService {
  late IO.Socket socket;
  late String _numElemento;
  String? lastMessageId;

  MessageService(this._numElemento) {
    initializeSocket();
  }

  void initializeSocket() {
    socket = IO.io('${ConfigBackend.backendUrlComunication}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true, // Reconexión automática habilitada
      'reconnection': true,
      'reconnectionAttempts': 10000, // Número de intentos de reconexión
      'reconnectionDelay': 2000, // Retraso entre intentos de reconexión (ms)
    });

    socket.on('connect', _onConnect);
    socket.on('disconnect', _onDisconnect);
    socket.on('connect_error', _onConnectError);
    socket.on('receiveMessage', _onReceiveMessage);
    socket.on('notificarAsignacion', _onRecivedAsignacion);
    socket.on('notifyRequestCall', _onReceivedCallRequest);
  }

  void _onConnect(_) async {
    print('Connected to server');
    if (_numElemento.isNotEmpty) {
      socket.emit('setId', _numElemento);
    }

    try {
      final response = await http.get(Uri.parse(
          '${ConfigBackend.backendUrlComunication}/segucomunication/api/messagesGroupWEB/ids/$_numElemento'));

      if (response.statusCode == 200) {
        List<dynamic> groupIds = json.decode(response.body);

        for (var group in groupIds) {
          socket.emit('joinGroup', [group['GroupID'], _numElemento]);
          print('Usuario $_numElemento unido al grupo ${group['GroupID']}');
        }
      } else {
        print('Error obteniendo los GroupIDs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud GET: $e');
    }
  }

  void _onDisconnect(_) {
    print('Disconnected from server');
  }

  void _onConnectError(data) {
    print(
        '${ConfigBackend.backendUrlComunication}/segucomunication/api/messagesGroupWEB/ids/$_numElemento');
    print('Error de conexión: $data');
  }

  void _onReceiveMessage(data) {
    print('Nuevo mensaje recibido desde servidor: $data');
    String? messageId =
        data['messageId']; // Asumiendo que cada mensaje tiene un ID único

    if (messageId != null && messageId == lastMessageId) {
      print('Mensaje duplicado detectado y descartado');
      return;
    }

    lastMessageId = messageId;

    if (data['to'] != null) {
      _handlePrivateMessage(data);
    } else if (data['GRUPO_DESCRIP'] != null) {
      _handleGroupMessage(data);
    }
  }

  void _handlePrivateMessage(data) {
    if (data['MEDIA'] == 'AUDIO') {
      NotificationController.createNewNotification(
          "Mensaje de " + data['NOMBRE'], "Nota de voz");
    } else if (data['MEDIA'] == 'IMAGE') {
      NotificationController.createNewNotification(
          "Mensaje de " + data['NOMBRE'], "IMAGEN");
    } else if (data['MEDIA'] == 'TXT') {
      NotificationController.createNewNotification(
          "Mensaje de " + data['NOMBRE'], data['MENSAJE']);
    }
  }

  void _handleGroupMessage(data) {
    if (data['MEDIA'] == 'AUDIO') {
      NotificationController.createNewNotification(
          "Mensaje de " + data['GRUPO_DESCRIP'], "Nota de voz");
    } else if (data['MEDIA'] == 'VIDEO') {
      NotificationController.createNewNotification(
          "Mensaje de " + data['GRUPO_DESCRIP'], "Video recibido");
    } else if (data['MEDIA'] == 'IMAGE') {
      NotificationController.createNewNotification(
          "Mensaje de " + data['GRUPO_DESCRIP'], "IMAGEN");
    } else if (data['MEDIA'] == 'TXT') {
      NotificationController.createNewNotification(
          "Mensaje de " + data['GRUPO_DESCRIP'], data['MENSAJE']);
    }
  }

  void _onRecivedAsignacion(dynamic data) {
    // Supongamos que _numElemento está definido en tu clase

    // Imprimir el mensaje recibido
    print('Nueva asignación recibida desde el servidor: $data');

    // Asegúrate de que data es un Map
    if (data is Map) {
      // Verifica si data contiene la clave 'listaElementos' y si esta es una lista
      if (data.containsKey('listaElementos') &&
          data['listaElementos'] is List) {
        List<dynamic> listaElementos = data['listaElementos'];

        // Verifica si _numElemento está en listaElementos
        if (listaElementos.contains(int.parse(_numElemento.toString()))) {
          print('El elemento $_numElemento está en listaElementos');
          // Validar si es consigna o boletin
          if (data['type'] == 'CONSIGNA') {
            NotificationController.createNewNotification(
                "Nueva consigna recibida", "Consúltalo en el menú");
            print('Es una consigna');
          } else if (data['type'] == 'BOLETIN') {
            print('Es un boletín');
            NotificationController.createNewNotification(
                "Nuevo boletín recibido", "Consúltalo en el menú");
          }
        } else {
          print('El elemento $_numElemento no está en listaElementos');
        }
      } else {
        print('data no contiene una lista llamada listaElementos');
      }
    } else {
      print('data no es un mapa válido');
    }
  }

  void _onReceivedCallRequest(dynamic data) {
  // Imprimir el mensaje recibido
  print('Nueva solicitud de llamada recibida desde el servidor: $data');

  // Asegúrate de que data es un Map
  if (data is Map) {
    // Obtén el valor de 'from', 'callType' y 'callerName'
    String from = data['to'];
    String callType = data['type'];
    String callerName = data['callerName'];
    String callerNumber = data['from'];

    // Aquí puedes implementar la lógica que deseas realizar con el valor 'from'
    print('Llamada solicitada por el elemento: $callerName ($callerNumber)');
    print('Tipo de llamada: $callType');

    // Verificar si en from está _numElemento
    if (from.toString() == _numElemento.toString()) {
      // Si está, emite una notificación
      
      NotificationController.createNewNotification(
        "Solicitud de llamada",
        "Ingresa al chat de: $callerName ($callerNumber)"
      );

      // Reproducir sonido y vibrar simultáneamente
      _playRingtoneAndVibrate();
    }

  } else {
    print('Datos recibidos no son un Map válido.');
  }
}

void _playRingtoneAndVibrate() {
  final _audioPlayer = AudioPlayer();

  // Inicia la reproducción del tono de llamada
  _audioPlayer.setAsset('lib/assets/ringtone.mp3').then((_) {
    _audioPlayer.play().catchError((error) {
      print('Error reproduciendo tono de llamada: $error');
    });
  }).catchError((error) {
    print('Error cargando tono de llamada: $error');
  });

  // Inicia la vibración
  Vibration.hasVibrator().then((hasVibrator) {
    if (hasVibrator == true) {
      // Configura el patrón de vibración
      Vibration.vibrate(pattern: [500, 1000, 500, 2000]);
    }
  }).catchError((error) {
    print('Error al verificar la vibración: $error');
  });
}








}
