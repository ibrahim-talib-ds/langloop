import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';
import 'contact_support_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = <(String, String)>[
    (
      'How do I match with someone?',
      'Open the Home tab and tap the big "Match me now" button. '
          'Pick a topic, then wait while we pair you with another learner.',
    ),
    (
      'How long is a round?',
      'Each round is 5 minutes. When the timer ends, you\'ll both get a chance to rate the chat.',
    ),
    (
      'How do I become friends with someone?',
      'After a match, rate the session 4 stars or higher. If your partner does the same, '
          'you\'ll automatically become friends.',
    ),
    (
      'Is my video saved?',
      'No. LangLoop uses peer-to-peer WebRTC — your video never touches our servers.',
    ),
    (
      'How do I delete my account?',
      'Go to Profile → Delete my account. Your data is anonymized within seconds.',
    ),
    (
      'Why was I banned?',
      'Bans happen after reports of abuse, nudity, or hate speech. '
          'If you believe this was a mistake, email support@langloop.app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(AppIcons.back, color: c.text),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle(c, 'Frequently asked'),
          const SizedBox(height: 8),
          ..._faqs.map(
            (f) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: c.border),
              ),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: c.primary,
                collapsedIconColor: c.textSub,
                title: Text(
                  f.$1,
                  style: TextStyle(
                    color: c.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    f.$2,
                    style: TextStyle(
                      color: c.textSub,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(c, 'Still need help?'),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ContactSupportScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: c.primary, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.support_agent_rounded, color: c.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send us a message',
                            style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Directly reach our team — we reply in 48h',
                            style: TextStyle(color: c.textSub, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: c.textSub),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(AppColors c, String text) {
    return Text(
      text,
      style: TextStyle(
        color: c.text,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

}
