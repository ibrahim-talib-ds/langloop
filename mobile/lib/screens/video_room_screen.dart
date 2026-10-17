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

class _VideoRoomScreenState extends State<VideoRoomScreen>
    with TickerProviderStateMixin {
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
  bool _remoteReady = false;

  int _secondsLeft = 300;
  Timer? _timer;

  // Animations
  late final AnimationController _fade;
  late final AnimationController _pulse;
  late final AnimationController _incoming;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _incoming = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
        setState(() {
          _peerReady = true;
        });
        _incoming.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _remoteReady = true);
        });
        break;
      case 'connected':
        setState(() => _connected = true);
        break;
      case 'disconnected':
      case 'peerOffline':
      case 'hangup':
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

  Color get _timerColor {
    if (_secondsLeft <= 30) return AppPalette.danger;
    if (_secondsLeft <= 60) return const Color(0xFFFFB800);
    return Colors.white;
  }

  Future<void> _endMatch() async {
    if (_ending) return;
    setState(() => _ending = true);
    _timer?.cancel();

    // Compute how long the call actually lasted
    final elapsed = 300 - _secondsLeft;

    try {
      await AuthService.instance.endMatch(widget.matchId);
    } catch (_) {}
    await _rtc.hangup();

    if (!mounted) return;

    // Only show the rating screen if the call was substantial
    // (>60 seconds) — otherwise just go home.
    if (elapsed >= 60) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RatingScreen(
            matchId: widget.matchId,
            partnerId: widget.partnerId,
            partnerName: widget.partnerName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chat ended'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _switchCamera() async {
    if (_switchingCamera) return;
    setState(() => _switchingCamera = true);
    final ok = await _rtc.switchCamera();
    if (!mounted) return;
    setState(() => _switchingCamera = false);
    if (!ok) {
      _showError('Camera switch not available on this device');
    }
  }

  Future<void> _addFriend() async {
    try {
      final res = await AuthService.instance.requestFriend(widget.partnerId);
      if (!mounted) return;
      setState(() => _friendAdded = true);

      final status = (res['status'] as String?) ?? 'requested';
      final msg = status == 'auto_accepted'
          ? 'You and ${widget.partnerName} are now friends!'
          : status == 'already_friends'
              ? 'You are already friends'
              : 'Request sent to ${widget.partnerName}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
        ),
      );
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

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _rtc.dispose();
    _fade.dispose();
    _pulse.dispose();
    _incoming.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: Stack(
            children: [
              // ─── Remote video (fullscreen or small if enlarged) ───
              _buildRemoteVideo(c),

              // ─── Self preview (small or big) ───
              _buildSelfPreview(c),

              // ─── Top bar ───
              _buildTopBar(c),

              // ─── Add friend floating button ───
              _buildAddFriendButton(c),

              // ─── Bottom controls ───
              _buildControls(c),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Remote Video ───────────────────────────
  Widget _buildRemoteVideo(AppColors c) {
    if (_selfEnlarged) {
      // When self is enlarged, remote goes to a small corner
      return Positioned(
        right: 12,
        bottom: 130,
        child: GestureDetector(
          onTap: () => setState(() => _selfEnlarged = false),
          child: Container(
            width: 130,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFF141A12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _peerReady
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    mirror: false,
                  )
                : _remotePlaceholder(c, small: true),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: _remoteReady
          ? RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: false,
            )
          : Container(
              color: const Color(0xFF0A0F08),
              child: _remotePlaceholder(c),
            ),
    );
  }

  Widget _remotePlaceholder(AppColors c, {bool small = false}) {
    if (small) {
      return Center(
        child: Icon(
          Icons.person_rounded,
          size: 40,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final scale = 1 + 0.05 * _pulse.value;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.primary.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: AvatarCircle(
                    name: widget.partnerName,
                    size: 110,
                    online: true,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.partnerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _connected ? 'Connecting video…' : 'Waiting for partner…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: c.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────── Self preview ───────────────────────────
  Widget _buildSelfPreview(AppColors c) {
    if (_selfEnlarged) {
      // Big self preview fills the screen
      return Positioned.fill(
        child: Container(
          color: const Color(0xFF0A0F08),
          child: Stack(
            children: [
              _camOn
                  ? RTCVideoView(
                      _localRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            AppIcons.cameraOff,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Camera off',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
              // Tap to shrink back
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _selfEnlarged = false),
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // "You" label
              Positioned(
                left: 20,
                bottom: 140,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Small self preview (bottom-right by default)
    return Positioned(
      right: 16,
      bottom: 130,
      child: GestureDetector(
        onTap: () => setState(() => _selfEnlarged = true),
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF141A12),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _camOn
                  ? RTCVideoView(
                      _localRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    )
                  : Center(
                      child: Icon(
                        AppIcons.cameraOff,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 32,
                      ),
                    ),
              // Expand hint
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Top bar ───────────────────────────
  Widget _buildTopBar(AppColors c) {
    return Positioned(
      left: 12,
      right: 12,
      top: 12,
      child: Row(
        children: [
          // Topic pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.topicChat, size: 14, color: c.primary),
                const SizedBox(width: 6),
                Text(
                  widget.topic.replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Timer
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: _secondsLeft <= 60
                  ? Border.all(color: _timerColor, width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: _timerColor,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  _mmss,
                  style: TextStyle(
                    color: _timerColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Add friend button ───────────────────────────
  Widget _buildAddFriendButton(AppColors c) {
    if (_friendAdded) {
      // Show subtle "Added" badge in top-right corner
      return Positioned(
        right: 16,
        top: 64,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text(
                'Request sent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      right: 16,
      top: 64,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: _addFriend,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  'Request friend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Controls ───────────────────────────
  Widget _buildControls(AppColors c) {
    final wide = MediaQuery.of(context).size.width >= 700;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mic
          _ctrlButton(
            icon: _micOn ? AppIcons.mic : AppIcons.micOff,
            onTap: () {
              setState(() => _micOn = !_micOn);
              _rtc.toggleMic(_micOn);
            },
            active: _micOn,
          ),
          const SizedBox(width: 16),

          // Camera
          _ctrlButton(
            icon: _camOn ? AppIcons.video : AppIcons.cameraOff,
            onTap: () {
              setState(() => _camOn = !_camOn);
              _rtc.toggleCamera(_camOn);
            },
            active: _camOn,
          ),
          const SizedBox(width: 16),

          // Flip camera (mobile only — hide on wide desktop)
          if (!wide) ...[
            _ctrlButton(
              icon: Icons.cameraswitch_rounded,
              onTap: _switchingCamera ? null : _switchCamera,
              active: true,
              busy: _switchingCamera,
            ),
            const SizedBox(width: 16),
          ],

          // End call — big red
          _ctrlButton(
            icon: AppIcons.callEnd,
            onTap: _endMatch,
            danger: true,
            big: true,
          ),
        ],
      ),
    );
  }

  Widget _ctrlButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool active = false,
    bool danger = false,
    bool big = false,
    bool busy = false,
  }) {
    final size = big ? 68.0 : 58.0;
    return Material(
      color: danger
          ? AppPalette.danger
          : (active
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.55)),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: busy
              ? Center(
                  child: SizedBox(
                    width: big ? 24 : 20,
                    height: big ? 24 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : Icon(
                  icon,
                  color: Colors.white,
                  size: big ? 28 : 24,
                ),
        ),
      ),
    );
  }
}
