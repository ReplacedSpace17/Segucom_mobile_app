import 'package:flutter/material.dart';
import 'package:segucom_app/screens/NotificationsClass/NotificationHome.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:segucom_app/configBackend.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      'reconnectionAttempts': 5, // Número de intentos de reconexión
      'reconnectionDelay': 2000, // Retraso entre intentos de reconexión (ms)
    });

    socket.on('connect', _onConnect);
    socket.on('disconnect', _onDisconnect);
    socket.on('connect_error', _onConnectError);
    socket.on('receiveMessage', _onReceiveMessage);
  }

  void _onConnect(_) async {
    print('Connected to server');
    if (_numElemento.isNotEmpty) {
      socket.emit('setId', _numElemento);
    }

    try {
      final response = await http.get(Uri.parse('${ConfigBackend.backendUrlComunication}/segucomunication/api/messagesGroupWEB/ids/$_numElemento'));

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
    print('Error de conexión: $data');
  }

  void _onReceiveMessage(data) {
    print('Nuevo mensaje recibido desde servidor: $data');
    String? messageId = data['messageId']; // Asumiendo que cada mensaje tiene un ID único

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
    } else if (data['MEDIA'] == 'IMAGE') {
      NotificationController.createNewNotification(
          "Mensaje de " + data['GRUPO_DESCRIP'], "IMAGEN");
    } else if (data['MEDIA'] == 'TXT') {
      NotificationController.createNewNotification(
          "Mensaje de " + data['GRUPO_DESCRIP'], data['MENSAJE']);
    }
  }
}
