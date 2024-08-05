import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:segucom_app/RequestPermissionScreen.dart';
import 'package:segucom_app/Services_background/CallingService.dart';
import 'package:segucom_app/Services_background/MessagesService.dart';
import 'package:segucom_app/Services_background/VolumeService.dart';
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

/*
class MyHttpOverrides extends HttpOverrides {
  final SecurityContext securityContext;

  MyHttpOverrides(this.securityContext);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(securityContext)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true; // Permitir certificados no verificados solo para pruebas
  }
}

Future<SecurityContext> initializeSecurityContext() async {
  SecurityContext securityContext = SecurityContext.defaultContext;
  try {
    final data = await rootBundle.load('lib/assets/certificates/segubackend.com_2024.pem');
    securityContext.setTrustedCertificatesBytes(data.buffer.asUint8List());
  } catch (e) {
    print('Error setting trusted certificates: $e');
  }
  return securityContext;
}

*/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AwesomeNotifications().requestPermissionToSendNotifications();
  // Inicializa las notificaciones y el puerto de comunicación entre isolates
  await NotificationController.initializeLocalNotifications();
  await NotificationController.initializeIsolateReceivePort();

  //await Geolocator.openLocationSettings();
  //await Geolocator.requestPermission();
  //await Geolocator.isLocationServiceEnabled();

  //await Permission.microphone.request();
  //await Permission.camera.request();
  //SecurityContext securityContext = await initializeSecurityContext();
  //HttpOverrides.global = MyHttpOverrides(securityContext);
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
    //NotificationController.startListeningNotificationEvents();

    // Inicializa el servicio de llamadas
    /*
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
    */
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
        '/config': (context) => HomeScreen(),
        '/menu': (context) => MenuScreen(),
        '/notification-page': (context) => NotificationPage(
            receivedAction: NotificationController.initialAction!),
        '/permision': (context) => RequestPermissionScreen(),
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

  Future<String?> fetchAndroidID(String numeroElemento) async {
    final url = Uri.parse(
        '${ConfigBackend.backendUrl}/segucom/api/user/android/$numeroElemento');
    print('URL: $url');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Si la respuesta es exitosa, parsear el JSON
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String androidID = data['androidID'];
        print('Android ID obtenido: $androidID');
        return androidID; // Devuelve el androidID
      } else if (response.statusCode == 404) {
        print('Error: Número de teléfono no encontrado');
        return null; // Retorna null si no se encuentra
      } else {
        print('Error al obtener el Android ID: ${response.statusCode}');
        return null; // Retorna null en otros casos de error
      }
    } catch (e) {
      print('Error al realizar la solicitud: $e');
      return null; // Retorna null en caso de excepción
    }
  }

  Future<void> _autoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('authToken');
    final String? permisionApp = prefs.getString('configPermissions');
    String? androidID = prefs.getString('AndroidID');

    final String _tel = prefs.getInt('NumeroTel').toString();
    print("VALOR DE PERMISOS: $permisionApp");
    print("VALOR DE TOKEN: $authToken");

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
          // Obtener el androidID permitido
          String? androidIDPermitido = await fetchAndroidID(_tel);
          String androidIDActual = androidID.toString();
          print(androidIDActual);
          print(androidIDPermitido);

          // Comparar el androidID permitido con el actual
          if (androidIDPermitido.toString() == androidIDActual.toString()) {
            // Si la respuesta es exitosa, puedes procesar los datos aquí
            final Map<String, dynamic> userData = jsonDecode(response.body);
            print('Datos del usuario: $userData');
            final String _numElemento = prefs.getString('NumeroElemento')!;

            if (permisionApp != null) {
              await initializeService();
              Navigator.pushReplacementNamed(context, '/menu');
            } else {
              Navigator.pushReplacementNamed(context, '/permision');
            }
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/login');
          print(
              "############## valor de response.statusCode: ${response.statusCode}");
          print(permisionApp);
        }
      } catch (e) {
        print('Error en la solicitud HTTP: $e');
        Navigator.pushReplacementNamed(context, '/config');
      }
    } else {
      // Si no hay un token aún
      if (permisionApp == null) {
        Navigator.pushReplacementNamed(context, '/permision');
      } else {
        Navigator.pushReplacementNamed(context, '/config');
      }
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

/*
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
*/
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    service.setForegroundNotificationInfo(
      title: 'SEGUCOM SERVICE',
      content: 'Service is running in the background',
    );
  }

  late IO.Socket socket;
  final UbicationService _ubicationService = UbicationService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await NotificationController
      .initializeLocalNotifications(); // Asegúrate de inicializar aquí
  await _createNotificationChannel(
      flutterLocalNotificationsPlugin); // Crea el canal aquí

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? authToken = prefs.getString('authToken');
  final String _tel = prefs.getInt('NumeroTel').toString();
  final String _numElemento = prefs.getString('NumeroElemento')!;

  NotificationController.startListeningNotificationEvents();

  final VolumeService volumeService = VolumeService(_numElemento, _tel);

  if (authToken != null) {
    final MessageService messageService = MessageService(_numElemento);

    Timer.periodic(const Duration(minutes: 10), (timer) async {
      if (service is AndroidServiceInstance &&
          await service.isForegroundService()) {
        // Configurar la notificación en primer plano

        try {
          await _ubicationService.sendLocation("", _tel, _numElemento);
        } catch (e) {
          print("Error al enviar ubicación: $e");
        }
      }
    });
  }
}

Future<void> requestPermissions() async {
  // Solicitar permisos de ubicación
  var statusFineLocation = await Permission.locationWhenInUse.request();
  var statusCoarseLocation = await Permission.locationAlways.request();
  var statusBackgroundLocation = await Permission.location.request();

  // Comprobar si se han concedido todos los permisos
  if (statusFineLocation.isGranted &&
      statusCoarseLocation.isGranted &&
      statusBackgroundLocation.isGranted) {
    print("Todos los permisos de ubicación concedidos");
  } else {
    print("Algunos permisos de ubicación no fueron concedidos");
  }
}

Future<void> _createNotificationChannel(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id del canal
    'MY FOREGROUND SERVICE', // nombre del canal
    description:
        'This channel is used for important notifications.', // descripción
    importance: Importance.high,
  );

  // Crea el canal de notificación
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> initializeService() async {
  await requestPermissions(); // Solicita permisos primero

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

  // Crea el canal de notificación
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





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////- permsos
