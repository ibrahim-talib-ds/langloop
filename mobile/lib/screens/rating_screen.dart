import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';
import '../widgets/ui_kit.dart';
import 'home_screen.dart';
import '../widgets/app_logo.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({
    super.key,
    required this.matchId,
    required this.partnerId,
    required this.partnerName,
  });

  final String matchId;
  final String partnerId;
  final String partnerName;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _stars = 0;
  final _comment = TextEditingController();
  bool _busy = false;
  bool _done = false;
  bool _becameFriends = false;
  int _xpGained = 0;
  String? _error;

  Future<void> _submit() async {
    if (_stars == 0) {
      setState(() => _error = 'Please pick a rating first');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await AuthService.instance.rateMatch(
        widget.matchId,
        stars: _stars,
        comment: _comment.text.trim(),
      );
      setState(() {
        _done = true;
        _becameFriends = res['became_friends'] == true;
        _xpGained = (res['xp_gained'] as int?) ?? 0;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _done ? _successView(c) : _ratingView(c),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ratingView(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: AppLogo(size: 90)),
        const SizedBox(height: 20),
        Text(
          'How was your chat?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.text,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'You just practiced with ${widget.partnerName}.\nRate the session to help them improve.',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textSub, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < _stars;
            return GestureDetector(
              onTap: () => setState(() => _stars = i + 1),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                scale: filled ? 1.12 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? AppIcons.star : AppIcons.starEmpty,
                    size: 44,
                    color: filled ? c.primary : c.textSub.withValues(alpha: 0.5),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 26),

        TextField(
          controller: _comment,
          maxLines: 3,
          style: TextStyle(color: c.text),
          decoration: const InputDecoration(
            hintText: 'Add a nice comment (optional)',
          ),
        ),
        const SizedBox(height: 20),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              _error!,
              style: TextStyle(color: c.danger, fontSize: 13),
            ),
          ),

        PillButton(
          label: 'Submit rating',
          icon: AppIcons.send,
          busy: _busy,
          onTap: _submit,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _goHome,
          child: Text(
            'Skip',
            style: TextStyle(color: c.textSub),
          ),
        ),
      ],
    );
  }

  Widget _successView(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: AppLogo(size: 100)),
        const SizedBox(height: 26),
        Text(
          'Thanks for the feedback!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.text,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 26),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(AppIcons.xp, color: c.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '+$_xpGained XP',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Streak +1',
                    style: TextStyle(
                      color: c.textSub,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_becameFriends) ...[
                const SizedBox(height: 14),
                Divider(color: c.border),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(AppIcons.friends, color: c.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You and ${widget.partnerName} are now friends!',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 26),
        PillButton(
          label: 'Back to home',
          icon: AppIcons.home,
          onTap: _goHome,
        ),
      ],
    );
  }
}
