import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebRTC Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallScreen(
                  from: 'user1',
                  to: 'user2',
                ),
              ),
            );
          },
          child: Text('Start Call'),
        ),
      ),
    );
  }
}

class CallScreen extends StatefulWidget {
  final String from;
  final String to;

  CallScreen({required this.from, required this.to});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late IO.Socket socket;
  late RTCPeerConnection _peerConnection;
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  late MediaStream _localStream;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _connectSocket();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection.close();
    _localStream.dispose();
    socket.disconnect();
    super.dispose();
  }

  void _initRenderers() async {
    _localRenderer = RTCVideoRenderer();
    await _localRenderer.initialize();
    _remoteRenderer = RTCVideoRenderer();
    await _remoteRenderer.initialize();
  }

  void _connectSocket() {
    socket = IO.io('http://192.168.1.76:3001', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      _createPeerConnection().then((pc) {
        _peerConnection = pc;
        _createOffer();
      });
    });

    socket.on('call', (data) async {
      await _peerConnection.setRemoteDescription(RTCSessionDescription(
          data['offer']['sdp'], data['offer']['type']));
      RTCSessionDescription answer = await _peerConnection.createAnswer();
      await _peerConnection.setLocalDescription(answer);
      socket.emit('answer', {
        'from': widget.from,
        'to': widget.to,
        'answer': answer.toMap(),
      });
    });

    socket.on('answer', (data) async {
      await _peerConnection.setRemoteDescription(RTCSessionDescription(
          data['answer']['sdp'], data['answer']['type']));
    });

    socket.on('candidate', (data) async {
      await _peerConnection.addCandidate(RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex']));
    });
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);

    _localStream.getTracks().forEach((track) {
      pc.addTrack(track, _localStream);
    });

    pc.onIceCandidate = (candidate) {
      socket.emit('candidate', {
        'from': widget.from,
        'to': widget.to,
        'candidate': candidate.toMap(),
      });
    };

    pc.onAddStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };

    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription offer = await _peerConnection.createOffer();
    await _peerConnection.setLocalDescription(offer);
    socket.emit('call', {
      'from': widget.from,
      'to': widget.to,
      'offer': offer.toMap(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Llamada en curso'),
      ),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(_localRenderer, mirror: true),
          ),
          Expanded(
            child: RTCVideoView(_remoteRenderer),
          ),
        ],
      ),
    );
  }
}
