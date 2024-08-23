import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';

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
  String? _pdfFilePath;

  @override
  void initState() {
    super.initState();
    if (WebView.platform is SurfaceAndroidWebView) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  void _handleError() {
    setState(() {
      _hasError = true;
      _isLoading = true;
    });
    _webViewController.goBack();
  }

  Future<void> _downloadFile(String url) async {
    try {
      final dio = Dio();
      final appDocDir = await getApplicationDocumentsDirectory();
      final fileName = url.split('/').last;
      final filePath = '${appDocDir.path}/$fileName';

      final fileExists = await File(filePath).exists();
      if (fileExists) {
        print('El archivo ya está descargado en $filePath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abriendo archivo PDF...'),
          ),
        );
      } else {
        await dio.download(url, filePath);
        setState(() {
          _pdfFilePath = filePath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Obteniendo archivo PDF...'),
          ),
        );
      }

      // Abre el archivo PDF
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewScreen(filePath: filePath),
        ),
      );
    } catch (e) {
      print('Error al descargar el archivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar el archivo.'),
        ),
      );
    }
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
                color: const Color.fromARGB(255, 34, 34, 34),
                fontSize: 16,
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
                _hasError = false;
                _currentUrl = url;
              });
            },
            navigationDelegate: (NavigationRequest request) {
              if (request.url.endsWith('.pdf')) {
                _downloadFile(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onWebResourceError: (WebResourceError error) {
              print('Error de carga: ${error.description}');
              _handleError();
            },
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Container(),
        ],
      ),
    );
  }
}

class PDFViewScreen extends StatelessWidget {
  final String filePath;

  PDFViewScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vista PDF'),
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: true,
        pageSnap: true,
        onRender: (_pages) {
          print('PDF renderizado');
        },
        onError: (error) {
          print('Error al renderizar PDF: $error');
        },
        onPageError: (page, error) {
          print('Error en la página $page: $error');
        },
        onViewCreated: (PDFViewController pdfViewController) {
          print('PDFViewController creado');
        },
      ),
    );
  }
}
