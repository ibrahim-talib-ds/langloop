import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final String appId = "362ac9b730a2499199766380f58eecc6";

  late final RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _micOn = true;
  bool _camOn = true;
  bool _friendAdded = false;
  bool _connecting = true;
  String? _errorMsg;

  int _secondsLeft = 300;
  Timer? _timer;

  String _sanitize(String raw) => raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  @override
  void initState() {
    super.initState();
    _initAgora();
    _startTimer();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) setState(() { _localUserJoined = true; _connecting = false; });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (mounted) { setState(() => _remoteUid = null); _endMatch(); }
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    // Get the token from our FastAPI backend
    final channelId = _sanitize(widget.matchId);
    final uid = DateTime.now().millisecondsSinceEpoch % 100000;

    try {
      final res = await ApiClient.instance.post('/video/token', body: {
        'channelName': channelId,
        'uid': uid,
      });
      final token = res['token'] as String;

      await _engine.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
    } catch (e) {
      print("Agora Join Error: $e");
      if (mounted) setState(() {
        _connecting = false;
        _errorMsg = e.toString();
      });
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
    try { await AuthService.instance.endMatch(widget.matchId); } catch (_) {}
    await _engine.leaveChannel();
    await _engine.release();

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
    _engine.leaveChannel();
    _engine.release();
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
              child: _remoteUid != null
                  ? AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _engine,
                        canvas: VideoCanvas(uid: _remoteUid),
                        connection: RtcConnection(channelId: _sanitize(widget.matchId)),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF0A0F08),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AvatarCircle(name: widget.partnerName, size: 100),
                            const SizedBox(height: 20),
                            if (_connecting) const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 20),
                            if (_errorMsg != null)
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text('Error: $_errorMsg', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12)),
                              )
                            else
                              Text(_connecting ? 'Connecting...' : 'Waiting for partner...', style: const TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
                    ),
            ),
            Positioned(
              right: 16, bottom: 130,
              child: Container(
                width: 120, height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30),
                  color: const Color(0xFF141A12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _camOn && _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const Center(child: Icon(Icons.videocam_off, color: Colors.white54, size: 40)),
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
                              onTap: () async {
                                try {
                                  await AuthService.instance.requestFriend(widget.partnerId);
                                  setState(() => _friendAdded = true);
                                } catch (_) {}
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text('+ Friend', style: TextStyle(color: Colors.white, fontSize: 12)),
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
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ctrl(icon: _micOn ? AppIcons.mic : AppIcons.micOff, onTap: () {
                    setState(() => _micOn = !_micOn);
                    _engine.muteLocalAudioStream(!_micOn);
                  }),
                  const SizedBox(width: 16),
                  _ctrl(icon: _camOn ? AppIcons.video : AppIcons.cameraOff, onTap: () {
                    setState(() => _camOn = !_camOn);
                    _engine.muteLocalVideoStream(!_camOn);
                  }),
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
          width: big ? 68 : 58, height: big ? 68 : 58,
          child: Icon(icon, color: Colors.white, size: big ? 28 : 24),
        ),
      ),
    );
  }
}
