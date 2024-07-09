import 'dart:io';

import 'package:flutter/material.dart';

import 'screens/Login/login_screen.dart';
import 'screens/Register/register_screen.dart';
import 'screens/Config/ScreenBackendConfig.dart';

import 'screens/SplashScreen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = new MyHttpOverrides();
  runApp(SegucomApp());
}

class SegucomApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Segucom App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/configBackend': (context) => ConfigScreen(),
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}
