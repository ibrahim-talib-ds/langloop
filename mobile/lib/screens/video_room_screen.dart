import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../services/auth_service.dart';
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
  final int appID = 1052798588;
  final String appSign = "252667b1c0b1be5fd1351dbac95d9922c950ac0460e07caef0dd7d191cf5c177";

  int _localViewID = 1001;
  int _remoteViewID = 1002;
  
  bool _camOn = true;
  bool _micOn = true;
  bool _isFrontCamera = true;
  bool _friendAdded = false;
  bool _selfEnlarged = false;
  bool _connected = false;
  
  String? _remoteStreamID;
  int _secondsLeft = 300;
  Timer? _timer;

  String _sanitize(String raw) => raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');

  @override
  void initState() {
    super.initState();
    _initZego();
    _startTimer();
  }

  Future<void> _initZego() async {
    final me = AuthService.instance.user;
    final myId = _sanitize(me?['id'] as String? ?? '');
    final roomId = _sanitize(widget.matchId);

    // 1. Create Engine
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(appID, ZegoScenario.Default, appSign: appSign)
    );

    // 2. Login Room
    ZegoExpressEngine.instance.loginRoom(
      roomId, 
      ZegoUser(myId, me?['full_name'] ?? 'User')
    );

    // 3. Enable Camera & Mic
    await ZegoExpressEngine.instance.enableCamera(true);
    await ZegoExpressEngine.instance.enableMicrophone(true);
    
    // 4. Start Preview & Publish
    await ZegoExpressEngine.instance.startPreview(ZegoCanvas(_localViewID));
    await ZegoExpressEngine.instance.startPublishingStream('stream_$myId');

    // 5. Listen for Partner
    ZegoExpressEngine.instance.setEventHandler(
      ZegoEventHandler(
        onRoomStreamUpdate: (roomID, updateType, streamList, extendedData) {
          if (updateType == ZegoUpdateType.Add && streamList.isNotEmpty) {
            setState(() {
              _remoteStreamID = streamList.first.streamID;
              _connected = true;
            });
            ZegoExpressEngine.instance.startPlayingStream(
              _remoteStreamID!, 
              ZegoCanvas(_remoteViewID)
            );
          }
        },
      ),
    );
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
    try { await AuthService.instance.endMatch(widget.matchId); } catch (_) {}
    
    ZegoExpressEngine.instance.stopPreview();
    ZegoExpressEngine.instance.stopPublishingStream();
    ZegoExpressEngine.instance.logoutRoom(_sanitize(widget.matchId));
    ZegoExpressEngine.destroyEngine();

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

  Future<void> _addFriend() async {
    try {
      await AuthService.instance.requestFriend(widget.partnerId);
      if (!mounted) return;
      setState(() => _friendAdded = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    ZegoExpressEngine.instance.stopPreview();
    ZegoExpressEngine.instance.stopPublishingStream();
    ZegoExpressEngine.instance.logoutRoom(_sanitize(widget.matchId));
    ZegoExpressEngine.destroyEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Partner Video (Remote)
            Positioned.fill(
              child: _connected 
                ? ZegoPlatformView(_remoteViewID.toString()) 
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
                          const Text('Connecting video...', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
            ),

            // 2. Self Video (Local)
            Positioned(
              right: 16,
              bottom: _selfEnlarged ? null : 130,
              top: _selfEnlarged ? 80 : null,
              child: GestureDetector(
                onTap: () => setState(() => _selfEnlarged = !_selfEnlarged),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _selfEnlarged ? MediaQuery.of(context).size.width - 32 : 120,
                  height: _selfEnlarged ? MediaQuery.of(context).size.height - 200 : 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white30),
                    color: const Color(0xFF141A12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _camOn
                      ? ZegoPlatformView(_localViewID.toString())
                      : const Center(child: Icon(Icons.videocam_off, color: Colors.white54, size: 40)),
                ),
              ),
            ),

            // 3. Top Bar (Topic, Add Friend, Timer)
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

            // 4. Bottom Controls (Mic, Cam, Flip, End)
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
                  _ctrl(
                    icon: Icons.cameraswitch_rounded,
                    onTap: () {
                      setState(() => _isFrontCamera = !_isFrontCamera);
                      ZegoExpressEngine.instance.useFrontCamera(_isFrontCamera);
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
      color: danger ? AppPalette.danger : Colors.white24,
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

// Custom view for Flutter Web
class ZegoPlatformView extends StatelessWidget {
  final String viewID;
  const ZegoPlatformView(this.viewID, {super.key});

  @override
  Widget build(BuildContext context) {
    return ZegoExpressEngine.instance.createCanvasView(
      (viewID) => ZegoCanvas(viewID),
    ).build(context);
  }
}
