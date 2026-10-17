import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';

/// Modal that appears when a user runs out of daily minutes.
class OutOfMinutesSheet extends StatelessWidget {
  const OutOfMinutesSheet({
    super.key,
    required this.usedToday,
    required this.dailyLimit,
    required this.bonusMinutes,
  });

  final int usedToday;
  final int dailyLimit;
  final int bonusMinutes;

  /// Show it. Returns `true` if the user tapped "Invite a friend".
  static Future<bool> show(
    BuildContext context, {
    required int usedToday,
    required int dailyLimit,
    required int bonusMinutes,
  }) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (_) => OutOfMinutesSheet(
        usedToday: usedToday,
        dailyLimit: dailyLimit,
        bonusMinutes: bonusMinutes,
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),

            // Gift icon with glow
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                size: 52,
                color: c.primary,
              ),
            ),
            const SizedBox(height: 22),

            // Title
            Text(
              "You've used today's free minutes",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              'Come back tomorrow, or unlock 30 more minutes right now by '
              'inviting a friend to LangLoop.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSub,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),

            // Usage bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Today\'s practice',
                        style: TextStyle(
                          color: c.textSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$usedToday / $dailyLimit min',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: dailyLimit == 0 ? 1 : usedToday / dailyLimit,
                      minHeight: 8,
                      backgroundColor: c.border,
                      valueColor: AlwaysStoppedAnimation(c.primary),
                    ),
                  ),
                  if (bonusMinutes > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(AppIcons.streak,
                            color: c.primary, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '$bonusMinutes bonus minutes from invites',
                          style: TextStyle(
                            color: c.textSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),

            // CTA — Invite
            SizedBox(
              width: double.infinity,
              child: Material(
                color: c.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => Navigator.pop(context, true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard_rounded,
                            color: c.primaryFg, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Invite a friend, get 30 min',
                          style: TextStyle(
                            color: c.primaryFg,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary — Upgrade
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () {
                    Navigator.pop(context, false);
                    // Upgrade is not opened here — caller handles it.
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: c.border),
                    ),
                    child: Center(
                      child: Text(
                        'Upgrade to unlimited',
                        style: TextStyle(
                          color: c.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Maybe tomorrow',
                style: TextStyle(
                  color: c.textSub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
