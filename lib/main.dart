import 'package:flutter/material.dart';

import 'screens/Login/login_screen.dart';
import 'screens/Register/register_screen.dart';
import 'screens/Config/ScreenBackendConfig.dart';

import 'screens/SplashScreen.dart';

void main() {
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
