import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';
import '../widgets/home_widgets.dart';
import 'rating_screen.dart';

class VideoRoomScreen extends StatefulWidget {
  const VideoRoomScreen({
    super.key,
    required this.matchId,
    required this.partnerId,
    required this.partnerName,
    required this.topic,
  });

  final String matchId;
  final String partnerId;
  final String partnerName;
  final String topic;

  @override
  State<VideoRoomScreen> createState() => _VideoRoomScreenState();
}

class _VideoRoomScreenState extends State<VideoRoomScreen> {
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  Timer? _frameTimer;
  Timer? _timer;
  
  bool _camOn = true;
  bool _ending = false;
  bool _friendAdded = false;
  int _secondsLeft = 300;
  
  // Latest frame from partner
  String? _partnerFrame;
  
  @override
  void initState() {
    super.initState();
    _initCamera();
    _connectWs();
    _startTimer();
  }
  
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.low, // low resolution for speed
        enableAudio: false,
      );
      await _cameraController!.initialize();
      _startFrameLoop();
      if (mounted) setState(() {});
    } catch (e) {
      print('Camera init failed: $e');
    }
  }
  
  void _startFrameLoop() {
    _frameTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (!_camOn || _cameraController == null) return;
      if (!_cameraController!.value.isInitialized) return;
      
      try {
        final picture = await _cameraController!.takePicture();
        final bytes = await picture.readAsBytes();
        final base64Str = base64Encode(bytes);
        
        _channel?.sink.add(jsonEncode({
          'to': widget.partnerId,
          'image': base64Str,
        }));
        
        // Delete the temp file to save space
      } catch (_) {}
    });
  }
  
  void _connectWs() {
    final token = ApiClient.instance.token;
    if (token == null) return;
    
    final base = ApiClient.instance.baseUrl;
    final wsUrl = base
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://')
        .replaceFirst('/api/v1', '');
        
    final myId = AuthService.instance.user?['id'];
    final url = '$wsUrl/api/v1/video-stream/ws/$myId';
    
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen((msg) {
      try {
        final data = jsonDecode(msg);
        if (data['image'] != null) {
          setState(() {
            _partnerFrame = data['image'];
          });
        }
      } catch (_) {}
    });
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _endMatch();
    });
  }
  
  String get _mmss {
    final m = (_secondsLeft ~/ 60).toString().padLeft(1, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
  
  Future<void> _endMatch() async {
    if (_ending) return;
    setState(() => _ending = true);
    _timer?.cancel();
    _frameTimer?.cancel();
    try { await AuthService.instance.endMatch(widget.matchId); } catch (_) {}
    _channel?.sink.close();
    await _cameraController?.dispose();
    
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          matchId: widget.matchId,
          partnerId: widget.partnerId,
          partnerName: widget.partnerName,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _frameTimer?.cancel();
    _channel?.sink.close();
    _cameraController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Partner video (large)
            Positioned.fill(
              child: _partnerFrame != null
                  ? Image.memory(
                      base64Decode(_partnerFrame!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Container(
                      color: const Color(0xFF0A0F08),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AvatarCircle(name: widget.partnerName, size: 100),
                            const SizedBox(height: 20),
                            Text(
                              'Connecting video...',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            
            // My small camera preview
            Positioned(
              right: 16,
              bottom: 130,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _camOn && _cameraController != null && _cameraController!.value.isInitialized
                    ? CameraPreview(_cameraController!)
                    : Container(
                        color: const Color(0xFF141A12),
                        child: const Icon(Icons.videocam_off, color: Colors.white54),
                      ),
              ),
            ),
            
            // Top bar
            Positioned(
              top: 16, left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text(widget.topic, style: const TextStyle(color: Colors.white)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text(_mmss, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // Controls
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ctrl(
                    icon: _camOn ? AppIcons.video : AppIcons.cameraOff,
                    onTap: () => setState(() => _camOn = !_camOn),
                  ),
                  const SizedBox(width: 20),
                  _ctrl(icon: AppIcons.callEnd, danger: true, big: true, onTap: _endMatch),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _ctrl({required IconData icon, required VoidCallback onTap, bool danger = false, bool big = false}) {
    return Material(
      color: danger ? Colors.red : Colors.white24,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: big ? 68 : 58,
          height: big ? 68 : 58,
          child: Icon(icon, color: Colors.white, size: big ? 28 : 24),
        ),
      ),
    );
  }
}
