class ConfigBackend {

//  static String _backendUrl = 'https://192.168.1.90:3000'; // -- laptop casa
  static String _backendUrl = 'https://segubackend.com/backend/'; // -- laptop escuela

  static String get backendUrl => _backendUrl;



//  static String _backendUrlCommunication = 'https://192.168.1.90:3001'; // -- laptop casa
 // static String _backendUrlCommunication = 'https://segubackend.com/communication';
 static String _backendUrlCommunication = 'https://segubackend.com';

  static String get backendUrlComunication => _backendUrlCommunication;

  static set backendUrl(String value) {
    _backendUrl = value;
  }
}
