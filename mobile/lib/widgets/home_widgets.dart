import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'app_icon_image.dart';
import 'app_icons.dart';

/// ─────────────────────────────────────────────
///  Home screen building blocks
/// ─────────────────────────────────────────────

/// Avatar circle — initials or image, with optional online dot.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
    this.online = false,
    this.verified = false,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool online;
  final bool verified;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surface,
              border: Border.all(color: c.border, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? (imageUrl!.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(imageUrl!.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        imageUrl!.startsWith('http')
                            ? imageUrl!
                            : 'https://langloop-tv47.onrender.com$imageUrl',
                        fit: BoxFit.cover,
                      ))
                : Center(
                    child: Text(
                      _initials,
                      style: TextStyle(
                        color: c.text,
                        fontSize: size * 0.36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22C55E),
                  border: Border.all(color: c.bg, width: 2),
                ),
              ),
            ),
          if (verified)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.bg,
                ),
                child: Icon(
                  AppIcons.verified,
                  size: size * 0.30,
                  color: c.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stat tile — icon + value + label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
    this.imageAsset,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? accent;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = accent ?? c.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: imageAsset != null
              ? AppIconImage(
                  asset: imageAsset!,
                  size: 22,
                  color: color,
                  fallbackIcon: icon,
                )
              : Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: c.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: c.textSub,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// XP progress bar with level badge.
class XpBar extends StatelessWidget {
  const XpBar({
    super.key,
    required this.level,
    required this.xp,
    required this.nextXp,
    required this.progress,
  });

  final int level;
  final int xp;
  final int? nextXp;
  final int progress; // 0-100

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pct = (progress.clamp(0, 100)) / 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.level, size: 14, color: c.primaryFg),
                    const SizedBox(width: 5),
                    Text(
                      'LEVEL $level',
                      style: TextStyle(
                        color: c.primaryFg,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(AppIcons.xp, size: 14, color: c.primary),
              const SizedBox(width: 4),
              Text(
                '$xp XP',
                style: TextStyle(
                  color: c.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: c.border,
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                nextXp == null
                    ? 'Max level reached'
                    : '$xp / $nextXp XP',
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                nextXp == null ? '' : '${100 - progress} to next',
                style: TextStyle(
                  color: c.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Topic chip — selectable.
class TopicChip extends StatelessWidget {
  const TopicChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primary : c.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? c.primary : c.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? c.primaryFg : c.text,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? c.primaryFg : c.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big primary CTA with animated glow.
class MatchNowButton extends StatefulWidget {
  const MatchNowButton({
    super.key,
    required this.onTap,
    this.label = 'Match me now',
    this.sublabel = '5-minute round with a stranger',
  });

  final VoidCallback onTap;
  final String label;
  final String sublabel;

  @override
  State<MatchNowButton> createState() => _MatchNowButtonState();
}

class _MatchNowButtonState extends State<MatchNowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Animated outer glow
            Container(
              width: 220 + 30 * t,
              height: 220 + 30 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.primary.withValues(alpha: 0.22 * (1 - t * 0.4)),
                    c.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // Inner solid button
            Material(
              color: c.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onTap,
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.55),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.video, size: 42, color: c.primaryFg),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: c.primaryFg,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Section header — title + optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
  });

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Small "streak" pill for the header.
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIconImage(
            asset: 'assets/icons/icon_streak.png',
            size: 16,
            fallbackIcon: AppIcons.streak,
          ),
          const SizedBox(width: 5),
          Text(
            '${days}d',
            style: TextStyle(
              color: c.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
