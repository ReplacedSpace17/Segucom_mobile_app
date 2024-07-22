import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:segucom_app/Services_background/CallingService.dart';
import 'package:segucom_app/Services_background/MessagesService.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:segucom_app/Services_background/UbicationService.dart';
import 'package:segucom_app/Services_background/MessagesService.dart';
import 'package:segucom_app/configBackend.dart';
import 'package:segucom_app/screens/App.dart';
import 'package:segucom_app/screens/Home/Home_menu.dart';
import 'package:segucom_app/screens/NotificationsClass/NotificationHome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'screens/Login/login_screen.dart';
import 'screens/Register/register_screen.dart';
import 'screens/Config/ScreenBackendConfig.dart';
import 'screens/SplashScreen.dart';

class MyHttpOverrides extends HttpOverrides {
  final SecurityContext securityContext;

  MyHttpOverrides(this.securityContext);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(securityContext)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<SecurityContext> initializeSecurityContext() async {
  SecurityContext securityContext = SecurityContext.defaultContext;
  try {
    final data = await rootBundle.load('lib/assets/certificates/PrivateKey.pem');
    securityContext.setTrustedCertificatesBytes(data.buffer.asUint8List());
  } catch (e) {
    print('Error setting trusted certificates: $e');
  }
  return securityContext;
}


Future<void> main() async {
  
  
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa las notificaciones y el puerto de comunicación entre isolates
  await NotificationController.initializeLocalNotifications();
  await NotificationController.initializeIsolateReceivePort();

  

  await initializeService();
   await Geolocator.openLocationSettings();
  await Geolocator.requestPermission();
  await Geolocator.isLocationServiceEnabled();
  SecurityContext securityContext = await initializeSecurityContext();
  HttpOverrides.global = MyHttpOverrides(securityContext);
  runApp(SegucomApp());
}

class SegucomApp extends StatefulWidget {
  const SegucomApp({super.key});

  // La llave del navegador es necesaria para navegar usando métodos estáticos
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<SegucomApp> createState() => _SegucomAppState();
}

class _SegucomAppState extends State<SegucomApp> {
late CallingService _callingService;

  @override
  void initState() {
    NotificationController.startListeningNotificationEvents();
    final MessageService messageService = MessageService('80100');
    // Inicializa el servicio de llamadas
    _callingService = CallingService(
      callerName: 'Nombre del Llamador',  // Asigna un nombre de llamador apropiado
      callerNumber: 'Número del Llamador',  // Asigna un número de llamador apropiado
      userElementNumber: '80100',  // El número de elemento del usuario actual
    );
     // Llama al método initialize para configurar el servicio
    _callingService.initialize().then((_) {
      // Puedes agregar lógica adicional aquí después de la inicialización, si es necesario
    }).catchError((error) {
      print('Error al inicializar CallingService: $error');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Segucom App',
      navigatorKey: SegucomApp.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home:
          SplashScreen(), // Inicia con SplashScreen para verificar el estado de la sesión
      routes: {
        '/login': (context) => LoginScreen(),
        '/configBackend': (context) => ConfigScreen(),
        '/register': (context) => RegisterScreen(),
        '/config':(context) => HomeScreen(),
        '/menu': (context) => MenuScreen(),
        '/notification-page': (context) => NotificationPage(
            receivedAction: NotificationController.initialAction!),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');

    if (authToken != null) {
      final url =
          Uri.parse(ConfigBackend.backendUrl + '/segucom/api/data-protegida');

      try {
        final response = await http.get(
          url,
          headers: {
            'Authorization': authToken,
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          // Si la respuesta es exitosa, puedes procesar los datos aquí
          final Map<String, dynamic> userData = jsonDecode(response.body);
          print('Datos del usuario: $userData');

          // Navegar al menú principal u otra pantalla segura
          Navigator.pushReplacementNamed(context, '/menu');
        } else {
          // Si el token es inválido o ha expirado, muestra la pantalla de inicio de sesión
          Navigator.pushReplacementNamed(context, '/config');
        }
      } catch (e) {
        print('Error en la solicitud HTTP:' + e.toString());
        // Manejar errores de conexión u otros errores aquí
        Navigator.pushReplacementNamed(context, '/config');
      }
    } else {
      // No hay token guardado, navegar a la pantalla de inicio de sesión
      Navigator.pushReplacementNamed(context, '/config');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class NotificationPage extends StatelessWidget {
  final ReceivedAction receivedAction;

  const NotificationPage({Key? key, required this.receivedAction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Page'),
      ),
      body: Center(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(20)),
            const Text(
              'Notification Page',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Padding(padding: EdgeInsets.all(20)),
            Text(
              'Título: ${receivedAction.title}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Cuerpo: ${receivedAction.body}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'ID de la notificación: ${receivedAction.id}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Payload: ${receivedAction.payload}',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}


Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const notificationChannelId = 'my_foreground';
  const notificationId = 888;

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'SEGUCOM SERVICE',
      initialNotificationContent: 'Service is running in the background',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}





@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  late IO.Socket socket;
  final UbicationService _ubicationService = UbicationService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? authToken = prefs.getString('authToken');

  final String _tel = prefs.getInt('NumeroTel').toString();
  final String _numElemento = prefs.getString('NumeroElemento')!;

  // Instanciar MessageService con el número de elemento
  

  if (authToken != null) {
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          _ubicationService.sendLocation("", _tel, _numElemento);
          // Métodos a ejecutar en foreground
          // NotificationController.createNewNotification("Hola", "Ubicacion enviada");
        }
      }
    });
  }
}

