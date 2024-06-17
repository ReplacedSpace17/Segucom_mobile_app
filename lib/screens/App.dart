import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'lib/assets/fondoWhite.png',
              fit: BoxFit.cover,
            ),
          ),
          // Contenido de la pantalla
          Column(
            children: <Widget>[
              // Logo alineado arriba con un margen
              Container(
                margin: EdgeInsets.only(top: 120.0),
                child: Image.asset(
                  'lib/assets/logo.png',
                  width: 150,
                  height: 150,
                ),
              ),
              Spacer(),
              // Botones alineados al fondo con márgenes
              Container(
                margin: EdgeInsets.only(bottom: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    // Botón de acceder
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF073560), // Color de fondo
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 13.0),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                            fontWeight: FontWeight.w300, // Letra light
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    // Botón de registrarse
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          foregroundColor: Color(0xFF073560), // Color del texto
                          side: BorderSide(color: Color(0xFF073560)), // Color del borde
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 13.0),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'REGISTRARTE',
                          style: TextStyle(
                            fontWeight: FontWeight.w300, // Letra light
                            color:  Color(0xFF073560),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    // Botón de backend
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          foregroundColor: Color(0xFF073560), // Color del texto
                          side: BorderSide(color: Color(0xFF073560)), // Color del borde
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 13.0),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/configBackend');
                        },
                        child: Text(
                          'CONFIGURAR BACKEND',
                          style: TextStyle(
                            fontWeight: FontWeight.w300, // Letra light
                            color: Color(0xFF073560),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
