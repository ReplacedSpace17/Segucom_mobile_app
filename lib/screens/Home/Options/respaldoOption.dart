import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  WebViewScreen({required this.url, required this.title});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    // Verificar la plataforma para inicializar WebView correctamente
    if (WebView.platform is SurfaceAndroidWebView) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  void _handleError() {
    setState(() {
      _hasError = true;
      _isLoading = true; // Mostrar el loader mientras se intenta redirigir
    });
    // Intenta volver a la página anterior si hay un error de carga
    _webViewController.goBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () async {
              if (await _webViewController.canGoBack()) {
                _webViewController.goBack();
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Anterior',
              style: TextStyle(
                color: const Color.fromARGB(255, 34, 34, 34), // Color del texto
                fontSize: 16, // Tamaño del texto
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebView(
            initialUrl: widget.url,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _webViewController = webViewController;
            },
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
                _hasError = false; // Resetear el estado de error
                _currentUrl = url;
              });
            },
            navigationDelegate: (NavigationRequest request) {
              if (request.url.startsWith('https://www.youtube.com/')) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onWebResourceError: (WebResourceError error) {
              // Manejo de errores de red
              print('Error de carga: ${error.description}');
              _handleError();
            },
          ),
          _hasError
              ? Center(child: CircularProgressIndicator()) // Muestra el loader solo cuando hay un error
              : Container(), 
        ],
      ),
    );
  }
}
