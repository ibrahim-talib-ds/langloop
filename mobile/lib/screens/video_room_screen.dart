import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
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
  // TODO: Replace with your actual AppID and AppSign
  final int appID = 0;
  final String appSign = "YOUR_APP_SIGN";

  bool _engineCreated = false;
  bool _camOn = true;
  bool _micOn = true;
  int _secondsLeft = 300;
  Timer? _timer;

  Widget? _localView;
  int? _localViewID;
  Widget? _remoteView;
  int? _remoteViewID;

  String? _myStreamID;

  @override
  void initState() {
    super.initState();
    _initZego();
    _startTimer();
  }

  Future<void> _initZego() async {
    // 1. Set global event listeners BEFORE creating engine
    ZegoExpressEngine.onRoomStreamUpdate = (roomID, updateType, streamList, extendedData) {
      if (streamList.isNotEmpty) {
        _startPlaying(streamList.first.streamID);
      }
    };

    // 2. Create engine
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(
        appID,
        ZegoScenario.Default,
        appSign: appSign,
      ),
    );
    _engineCreated = true;

    // 3. Login room
    final me = AuthService.instance.user;
    final myId = me?['id'] as String? ?? 'unknown';
    final myName = me?['full_name'] ?? 'User';

    await ZegoExpressEngine.instance.loginRoom(
      widget.matchId,
      ZegoUser(myId, myName),
    );

    // 4. Start local preview
    await _startLocalPreview(myId);

    // 5. Start publishing
    _myStreamID = 'stream_$myId';
    await ZegoExpressEngine.instance.startPublishingStream(_myStreamID!);

    if (mounted) setState(() {});
  }

  Future<void> _startLocalPreview(String myId) async {
    final canvasWidget = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      _localViewID = viewID;
      ZegoExpressEngine.instance.startPreview(
        canvas: ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill),
      );
    });

    if (mounted) {
      setState(() => _localView = canvasWidget);
    }
  }

  Future<void> _startPlaying(String streamID) async {
    if (_remoteViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(_remoteViewID!);
      _remoteViewID = null;
    }

    final canvasWidget = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      _remoteViewID = viewID;
      ZegoExpressEngine.instance.startPlayingStream(
        streamID,
        canvas: ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill),
      );
    });

    if (mounted) {
      setState(() => _remoteView = canvasWidget);
    }
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
    _timer?.cancel();
    try {
      await AuthService.instance.endMatch(widget.matchId);
    } catch (_) {}

    await _cleanupZego();

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

  Future<void> _cleanupZego() async {
    if (!_engineCreated) return;

    if (_myStreamID != null) {
      ZegoExpressEngine.instance.stopPublishingStream();
    }
    ZegoExpressEngine.instance.stopPreview();

    if (_localViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(_localViewID!);
    }
    if (_remoteViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(_remoteViewID!);
    }

    await ZegoExpressEngine.instance.logoutRoom(widget.matchId);
    await ZegoExpressEngine.destroyEngine();
    _engineCreated = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cleanupZego();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _remoteView ??
                  Container(
                    color: const Color(0xFF0A0F08),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AvatarCircle(name: widget.partnerName, size: 100),
                          const SizedBox(height: 20),
                          const Text(
                            'Waiting for partner video...',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
            Positioned(
              right: 16,
              bottom: 130,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30),
                ),
                clipBehavior: Clip.antiAlias,
                child: _camOn && _localView != null
                    ? _localView!
                    : Container(
                        color: const Color(0xFF141A12),
                        child: const Icon(Icons.videocam_off, color: Colors.white54),
                      ),
              ),
            ),
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
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ctrl(
                    icon: _micOn ? AppIcons.mic : AppIcons.micOff,
                    onTap: () {
                      setState(() => _micOn = !_micOn);
                      ZegoExpressEngine.instance.muteMicrophone(!_micOn);
                    },
                  ),
                  const SizedBox(width: 16),
                  _ctrl(
                    icon: _camOn ? AppIcons.video : AppIcons.cameraOff,
                    onTap: () {
                      setState(() => _camOn = !_camOn);
                      ZegoExpressEngine.instance.enableCamera(_camOn);
                    },
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
