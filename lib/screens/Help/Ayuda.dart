import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  WebViewScreen({required this.url, required this.title});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView(); // Para Android
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          WebView(
            initialUrl: widget.url,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            navigationDelegate: (NavigationRequest request) {
              // Manejo de enlaces aquí, por ejemplo, abrir en el navegador
              if (request.url.startsWith('http')) {
                _launchInBrowser(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.open_in_browser),
              onPressed: () {
                _launchInBrowser(widget.url);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false);
    } else {
      throw 'Could not launch $url';
    }
  }
}

/*
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:url_launcher/url_launcher.dart'; // Importar url_launcher

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
      withLocalStorage: true, // Habilitar almacenamiento local
      hidden: true, // Ocultar el WebView hasta que esté cargado
      appCacheEnabled: true, // Habilitar el caché de la aplicación
      initialChild: Center(child: CircularProgressIndicator()), // Widget mientras carga la página
      // Configurar manejo de enlaces
      ignoreSSLErrors: true,
      userAgent: 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.96 Mobile Safari/537.36',
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.open_in_browser),
              onPressed: () {
                _launchInBrowser(url);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false);
    } else {
      throw 'Could not launch $url';
    }
  }
}
*/