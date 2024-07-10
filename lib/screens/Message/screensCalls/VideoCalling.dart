import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ScreenCalling extends StatefulWidget {
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final VoidCallback onHangUp;
  final String callerName;
  final String callerNumber;

  ScreenCalling({
    required this.localRenderer,
    required this.remoteRenderer,
    required this.onHangUp,
    required this.callerName,
    required this.callerNumber, MediaStream? incomingStream,
  });

  @override
  _ScreenCallingState createState() => _ScreenCallingState();
}

class _ScreenCallingState extends State<ScreenCalling> {
  late Stopwatch _stopwatch;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {});
    });
    _stopwatch.start();
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancelar el temporizador
    _stopwatch.stop(); // Detener el cronómetro
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: RTCVideoView(widget.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          ),
          Positioned(
            left: 16.0,
            top: 16.0,
            child: Container(
              width: 100.0,
              height: 150.0,
              child: RTCVideoView(widget.localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),
          Positioned(
            top: 40.0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('lib/assets/iconUser.png', width: 50, height: 50),
                    SizedBox(width: 8.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.callerName,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        Text(
                          widget.callerNumber,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        Text(
                          _formattedTime(),
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    // Llamar a la función de colgar y cancelar la llamada
                    widget.onHangUp();
                    // Detener el temporizador y el cronómetro
                    _timer.cancel();
                    _stopwatch.stop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEC5454),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Icon(Icons.call_end, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formattedTime() {
    final duration = _stopwatch.elapsed;
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
