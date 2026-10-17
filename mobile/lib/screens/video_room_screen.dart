import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/auth_service.dart';
import '../services/webrtc_service.dart';
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
  final _rtc = WebRtcService();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  bool _micOn = true;
  bool _camOn = true;
  bool _connected = false;
  bool _peerReady = false;
  bool _ending = false;
  bool _friendAdded = false;
  bool _selfEnlarged = false;
  bool _switchingCamera = false;

  int _secondsLeft = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _rtc.onEvent = _onRtcEvent;

    final me = AuthService.instance.user;
    final myId = me?['id'] as String?;
    if (myId == null) return;

    try {
      await _rtc.connect(
        myUserId: myId,
        partnerId: widget.partnerId,
        topic: widget.topic,
      );
    } catch (e) {
      _showError('Could not start video: $e');
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _endMatch();
    });
  }

  void _onRtcEvent(String event, dynamic data) {
    switch (event) {
      case 'localStream':
        _localRenderer.srcObject = data as MediaStream;
        break;
      case 'remoteStream':
        _remoteRenderer.srcObject = data as MediaStream;
        setState(() => _peerReady = true);
        break;
      case 'connected':
        setState(() => _connected = true);
        break;
      case 'disconnected':
        if (!_ending) setState(() => _connected = false);
        break;
      case 'error':
        _showError(data?.toString() ?? 'WebRTC error');
        break;
    }
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
    try { await AuthService.instance.endMatch(widget.matchId); } catch (_) {}
    await _rtc.hangup();

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

  Future<void> _switchCamera() async {
    if (_switchingCamera) return;
    setState(() => _switchingCamera = true);
    final ok = await _rtc.switchCamera();
    if (!mounted) return;
    setState(() => _switchingCamera = false);
    if (!ok) _showError('Camera switch not available on this device');
  }

  Future<void> _addFriend() async {
    try {
      final res = await AuthService.instance.requestFriend(widget.partnerId);
      if (!mounted) return;
      setState(() => _friendAdded = true);
      final status = res['status'] as String? ?? 'requested';
      _showSuccess(status == 'auto_accepted'
          ? 'You and ${widget.partnerName} are now friends!'
          : 'Request sent to ${widget.partnerName}');
    } catch (e) {
      if (!mounted) return;
      _showError('Could not send request: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.surface,
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _rtc.dispose();
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
            // Remote Video or Placeholder
            Positioned.fill(
              child: _peerReady
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: false,
                    )
                  : Container(
                      color: const Color(0xFF0A0F08),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AvatarCircle(name: widget.partnerName, size: 100),
                            const SizedBox(height: 20),
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 20),
                            const Text(
                              'Connecting video...',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Self Preview
            Positioned(
              right: 16,
              bottom: _selfEnlarged ? null : 130,
              top: _selfEnlarged ? 80 : null,
              child: GestureDetector(
                onTap: () => setState(() => _selfEnlarged = !_selfEnlarged),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _selfEnlarged ? MediaQuery.of(context).size.width - 32 : 120,
                  height: _selfEnlarged ? MediaQuery.of(context).size.width - 32 : 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30),
                    color: const Color(0xFF141A12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _camOn
                      ? RTCVideoView(
                          _localRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          mirror: true,
                        )
                      : const Center(
                          child: Icon(Icons.videocam_off, color: Colors.white54, size: 40),
                        ),
                ),
              ),
            ),

            // Top Bar
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
                  Row(
                    children: [
                      if (!_friendAdded)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: _addFriend,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text('+ Request Friend', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: Text(_mmss, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
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
                    icon: _micOn ? AppIcons.mic : AppIcons.micOff,
                    onTap: () {
                      setState(() => _micOn = !_micOn);
                      _rtc.toggleMic(_micOn);
                    },
                  ),
                  const SizedBox(width: 16),
                  _ctrl(
                    icon: _camOn ? AppIcons.video : AppIcons.cameraOff,
                    onTap: () {
                      setState(() => _camOn = !_camOn);
                      _rtc.toggleCamera(_camOn);
                    },
                  ),
                  const SizedBox(width: 16),
                  _ctrl(
                    icon: Icons.cameraswitch_rounded,
                    onTap: _switchingCamera ? null : _switchCamera,
                    busy: _switchingCamera,
                  ),
                  const SizedBox(width: 16),
                  _ctrl(icon: AppIcons.callEnd, danger: true, big: true, onTap: _endMatch),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrl({required IconData icon, required VoidCallback? onTap, bool danger = false, bool big = false, bool busy = false}) {
    return Material(
      color: danger ? AppPalette.danger : Colors.white24,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: big ? 68 : 58,
          height: big ? 68 : 58,
          child: busy 
              ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: big ? 28 : 24),
        ),
      ),
    );
  }
}
