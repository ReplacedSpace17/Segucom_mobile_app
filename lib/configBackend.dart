class ConfigBackend {
  //static String _backendUrl = 'https://9160-2806-103e-30-f054-aeae-a6b6-7cb9-8ae0.ngrok-free.app';
  //static String _backendUrl = 'http://192.168.1.76:3000'; -- desktop
  static String _backendUrl = 'http://192.168.1.90:3000'; // -- laptop casa
  //static String _backendUrl = 'http://192.168.100.123:3000'; // -- laptop escuela
  // static String _backendUrl = 'http://20.102.109.114:3000';
//https://9160-2806-103e-30-f054-aeae-a6b6-7cb9-8ae0.ngrok-free.app 
  static String get backendUrl => _backendUrl;


   //static String _backendUrlCommunication = 'http://192.168.1.76:3001'; -- desktop
   static String _backendUrlCommunication = 'http://192.168.1.90:3001'; // -- laptop casa
  // static String _backendUrlCommunication = 'http://192.168.100.123:3001'; // -- laptop escuela
  // static String _backendUrl = 'http://20.102.109.114:3000';
//https://9160-2806-103e-30-f054-aeae-a6b6-7cb9-8ae0.ngrok-free.app 
  static String get backendUrlComunication => _backendUrlCommunication;

  static set backendUrl(String value) {
    _backendUrl = value;
  }
}
