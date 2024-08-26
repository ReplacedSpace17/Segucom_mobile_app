import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'dart:async';

import 'package:segucom_app/screens/App.dart'; // Importa el paquete para el temporizador

void main() {
  runApp(const MyAppIncompatibility());
}

class MyAppIncompatibility extends StatelessWidget {
  const MyAppIncompatibility({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 2, 22, 58)),
        useMaterial3: true,
        
      ),
      home: const MyHomePage(title: 'Comprobación de instalación'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, bool> _installedApps = {};
  bool _loading = false;
  bool _checked = false;
  List<String> _incompatibleApps = [];
  Timer? _refreshTimer; // Temporizador para actualizar la vista

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancela el temporizador cuando se deshace del estado
    super.dispose();
  }

  Future<void> _checkInstalledApps() async {
    setState(() {
      _loading = true;
      _checked = false;
      _incompatibleApps = [];
    });

    await Future.delayed(const Duration(seconds: 3)); // Simulación de proceso

    final packageNames = [
      'com.icu.sos',
      'messenger.icu.io',
      'adminpatrol.icuinterface.io',
      'com.servicio.app'
    ];

    final installedApps = await Future.wait(packageNames.map((packageName) async {
      final installed = await DeviceApps.isAppInstalled(packageName);
      return MapEntry(packageName, installed);
    }));

    setState(() {
      _installedApps = Map.fromEntries(installedApps);
      _incompatibleApps = _installedApps.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      _loading = false;
      _checked = true;
    });
  }

  Future<void> _openAppSettings(String packageName) async {
    await DeviceApps.openAppSettings(packageName);

    // Inicia un temporizador para actualizar la lista de aplicaciones instaladas
    _refreshTimer?.cancel(); // Cancela cualquier temporizador anterior
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final installed = await DeviceApps.isAppInstalled(packageName);
      if (!installed) {
        timer.cancel(); // Detiene el temporizador si la aplicación ya no está instalada
        await _checkInstalledApps(); // Actualiza la lista de aplicaciones
      }
    });
  }

  Future<void> _continue() async {
    final notInstalled = await Future.wait(_incompatibleApps.map((packageName) async {
      final installed = await DeviceApps.isAppInstalled(packageName);
      return MapEntry(packageName, installed);
    }));

    final stillInstalled = notInstalled.where((entry) => entry.value).map((entry) => entry.key).toList();

    if (stillInstalled.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Las siguientes aplicaciones aún están instaladas: ${stillInstalled.join(', ')}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las incompatibilidades han sido resueltas.'),
        ),
      );
      Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _checked
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_incompatibleApps.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Se encontraron las siguientes incompatibilidades:',
                            style: Theme.of(context).textTheme.headline6?.copyWith(
                                  fontWeight: FontWeight.normal,
                                  color: const Color.fromARGB(255, 22, 22, 22),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ..._installedApps.entries.mapIndexed((index, entry) {
                        final packageName = entry.key;
                        final installed = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 3), // changes position of shadow
                                    ),
                                  ],
                                ),
                                width: MediaQuery.of(context).size.width * 0.7, // Botones ocupan el 70% del ancho
                                child: Column(
                                  children: [
                                    Text(
                                      'Incompatibilidad ${index + 1}: ${installed ? "Quitar paquete" : "Completado"}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: installed ? Colors.red : Colors.green,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (installed)
                                      const SizedBox(height: 10),
                                    if (installed)
                                      ElevatedButton(
                                        onPressed: () => _openAppSettings(packageName),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color.fromARGB(150, 174, 219, 248),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          minimumSize: Size(double.infinity, 50), // Asegura que el botón sea rectangular
                                        ),
                                        child: const Text('Desinstalar aplicación', style: TextStyle(color: Color.fromARGB(255, 41, 41, 41))),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(27, 25, 138, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 50),
                        ),
                        child: const Text('Continuar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _checkInstalledApps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 35, 5, 145),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 50),
                    ),
                    child: const Text('Comprobar Incompatibilidades', style: TextStyle(color: Colors.white)),
                  ),
      ),
    );
  }
}

// Extensión para mapIndexed
extension IterableIndexMap<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) sync* {
    var index = 0;
    for (var element in this) {
      yield f(index++, element);
    }
  }
}
