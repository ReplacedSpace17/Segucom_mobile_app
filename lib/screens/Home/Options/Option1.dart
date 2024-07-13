import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatelessWidget {
  final String url;
  final String title;

  WebViewScreen({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title'),
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          // Aquí puedes interactuar con el controlador de WebView si es necesario
        },
        onPageStarted: (String url) {
          // Se ejecuta cuando la página comienza a cargarse
        },
        onPageFinished: (String url) {
          // Se ejecuta cuando la página ha terminado de cargarse
        },
        navigationDelegate: (NavigationRequest request) {
          // Implementa lógica para manejar la navegación aquí, por ejemplo bloquear ciertos sitios
          if (request.url.startsWith('https://www.youtube.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        gestureNavigationEnabled: true, // Habilita la navegación con gestos
      ),
    );
  }
}



/*
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class WebViewScreen extends StatelessWidget {
  final String url;
  final String title;

  WebViewScreen({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      appBar: AppBar(
        title: Text('$title'),
      ),
      url: url,
      withJavascript: true,
      debuggingEnabled: true,
      // Otros parámetros opcionales
    );
  }
}
*/