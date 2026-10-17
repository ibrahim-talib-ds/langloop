import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';
import '../widgets/home_widgets.dart';
import '../widgets/out_of_minutes_sheet.dart';
import 'invite_screen.dart';
import 'video_room_screen.dart';

/// Real matchmaking screen.
/// 1. POST /match/join on mount
/// 2. Poll /match/status every 1.5s
/// 3. On match → VideoRoomScreen
/// 4. On cancel → POST /match/leave
/// 5. Auto-timeout after 90s
class MatchScreen extends StatefulWidget {
  const MatchScreen({
    super.key,
    required this.topic,
    this.language = 'en',
  });

  final String topic;
  final String language;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin {
  // Radar animation
  late final AnimationController _radar;
  // A subtle fade-in
  late final AnimationController _fadeIn;

  Timer? _poller;
  Timer? _timeoutTimer;
  bool _cancelled = false;
  String? _error;
  int _elapsed = 0;
  int _queueSize = 0;

  @override
  void initState() {
    super.initState();
    _radar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _startSearch();
  }

  Future<void> _startSearch() async {
    setState(() {
      _error = null;
      _elapsed = 0;
    });

    try {
      final res = await AuthService.instance.joinQueue(
        topic: widget.topic,
        language: widget.language,
      );

      // Already matched immediately
      if (res['state'] == 'matched') {
        _goToRoom(res);
        return;
      }

      setState(() {
          _queueSize = (res['queue_size'] as int?) ?? 0;
      });

      // Start polling
      _poller = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
        if (_cancelled) return;
        try {
          final s = await AuthService.instance.matchStatus();
          if (!mounted) return;
          _elapsed += 1;

          if (s['state'] == 'matched') {
            _poller?.cancel();
            _goToRoom(s);
            return;
          }
          setState(() {
            _queueSize = (s['queue_size'] as int?) ?? 0;
          });
        } catch (_) {
          // ignore transient polling errors
        }
      });

      // Timeout safety — 90 seconds
      _timeoutTimer = Timer(const Duration(seconds: 90), () async {
        if (_cancelled || !mounted) return;
        _poller?.cancel();
        await _leave();
        if (mounted) {
          setState(() => _error = 'No one joined in time. Try again.');
        }
      });
    } catch (e) {
      final msg = e.toString();

      // Out-of-minutes → show the friendly invite popup
      if (msg.contains('out_of_minutes') ||
          msg.contains('used today') ||
          msg.contains('used today\'s free minutes')) {
        if (!mounted) return;
        int used = 10;
        int limit = 10;
        int bonus = 0;
        try {
          final m = await AuthService.instance.fetchMinutes();
          used = (m['used_today'] as num?)?.toInt() ?? 10;
          limit = (m['daily_limit'] as num?)?.toInt() ?? 10;
          bonus = (m['bonus_minutes'] as num?)?.toInt() ?? 0;
        } catch (_) {}
        if (!mounted) return;
        final wantsInvite = await OutOfMinutesSheet.show(
          context,
          usedToday: used,
          dailyLimit: limit,
          bonusMinutes: bonus,
        );
        if (!mounted) return;
        if (wantsInvite) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InviteScreen()),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _error = msg;
        });
      }
    }
  }

  void _goToRoom(Map<String, dynamic> s) {
    final matchId = s['match_id'] as String?;
    final partnerId = s['partner_id'] as String?;
    final partnerName = (s['partner_username'] as String?) ?? 'Partner';
    if (matchId == null || partnerId == null) return;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => VideoRoomScreen(
          matchId: matchId,
          partnerId: partnerId,
          partnerName: partnerName,
          topic: widget.topic,
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: a.drive(Tween(begin: 0.96, end: 1.0)), child: child),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> _leave() async {
    try {
      await AuthService.instance.leaveQueue();
    } catch (_) {}
  }

  Future<void> _cancel() async {
    _cancelled = true;
    _poller?.cancel();
    _timeoutTimer?.cancel();
    await _leave();
    if (mounted) Navigator.maybePop(context);
  }

  @override
  void dispose() {
    _cancelled = true;
    _poller?.cancel();
    _timeoutTimer?.cancel();
    _radar.dispose();
    _fadeIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final u = AuthService.instance.user;
    final myName = (u?['full_name'] as String?)?.trim().isNotEmpty == true
        ? u!['full_name'] as String
        : (u?['username'] as String? ?? 'You');

    final mins = (_elapsed * 1.5 / 60).floor();
    final secs = ((_elapsed * 1.5) % 60).floor().toString().padLeft(2, '0');

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // ─── Top bar ───
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _roundIcon(
                      icon: AppIcons.back,
                      onTap: _cancel,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(AppIcons.topicChat, size: 14, color: c.primary),
                          const SizedBox(width: 6),
                          Text(
                            widget.topic.replaceAll('_', ' '),
                            style: TextStyle(
                              color: c.text,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Radar ───
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing rings
                        AnimatedBuilder(
                          animation: _radar,
                          builder: (_, __) {
                            return CustomPaint(
                              size: const Size(320, 320),
                              painter: _RadarPainter(
                                t: _radar.value,
                                color: c.primary,
                                border: c.border,
                              ),
                            );
                          },
                        ),
                        // Avatar in center
                        AvatarCircle(
                          name: myName,
                          size: 96,
                          online: true,
                        ),
                        // Orbit dot — showing "searching"
                        AnimatedBuilder(
                          animation: _radar,
                          builder: (_, __) {
                            final angle = _radar.value * 2 * 3.14159;
                            final r = 130.0;
                            final dx = r * _cos(angle);
                            final dy = r * _sin(angle);
                            return Transform.translate(
                              offset: Offset(dx, dy),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.primary.withValues(alpha: 0.7),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Status ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      _error ?? 'Finding someone to talk to…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _error != null ? c.danger : c.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error == null
                          ? 'Round is 5 minutes · tap cancel anytime'
                          : 'Tap try again to search again',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textSub,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_error == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Searching · $mins:$secs · $_queueSize in queue',
                              style: TextStyle(
                                color: c.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ─── Cancel / retry ───
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 26),
                child: _error == null
                    ? _ghostButton(
                        context,
                        label: 'Cancel',
                        icon: AppIcons.close,
                        onTap: _cancel,
                      )
                    : _primaryButton(
                        context,
                        label: 'Try again',
                        icon: AppIcons.video,
                        onTap: () {
                          setState(() => _error = null);
                          _startSearch();
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ghostButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: c.text),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: c.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: c.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: c.primaryFg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: c.primaryFg,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundIcon({required IconData icon, required VoidCallback onTap}) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.border),
            color: c.surface.withValues(alpha: 0.6),
          ),
          child: Icon(icon, size: 20, color: c.text),
        ),
      ),
    );
  }
}

/// ─── small math helpers (avoid dart:math import clutter)
double _sin(double x) => _taylorSin(x % (2 * 3.14159));
double _cos(double x) => _taylorSin((x + 1.5708) % (2 * 3.14159));
double _taylorSin(double x) {
  // good enough for animation (0..2π)
  final x2 = x * x;
  return x - x * x2 / 6 + x * x2 * x2 / 120 - x * x2 * x2 * x2 / 5040;
}

/// Radar rings painter.
class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.t, required this.color, required this.border});
  final double t;
  final Color color;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Static faint rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = border.withValues(alpha: 0.6);

    canvas.drawCircle(center, 70, ringPaint);
    canvas.drawCircle(center, 110, ringPaint);
    canvas.drawCircle(center, 150, ringPaint);

    // Animated pulse — 2 rings offset by half a cycle
    for (var i = 0; i < 2; i++) {
      final phase = (t + i * 0.5) % 1.0;
      final radius = 60 + phase * 100;
      final opacity = (1.0 - phase) * 0.5;
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.t != t || old.color != color || old.border != border;
}
