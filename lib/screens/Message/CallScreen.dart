import 'package:flutter/material.dart';

class CallScreen extends StatelessWidget {
  final String callerName;

  CallScreen({required this.callerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Llamada Entrante'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Llamada de $callerName',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.call_end, color: Colors.red, size: 50),
                  onPressed: () {
                    // Lógica para rechazar la llamada
                    Navigator.of(context).pop();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.call, color: Colors.green, size: 50),
                  onPressed: () {
                    // Lógica para aceptar la llamada
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
