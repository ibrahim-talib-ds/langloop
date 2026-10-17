import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(AppIcons.back, color: c.text),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Privacy & Safety'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card(c, 'What we collect', [
            'Your email, username, and password (hashed with bcrypt).',
            'Your profile details: name, bio, country, languages.',
            'Your practice history: matches, ratings, friends, XP.',
            'Your IP address (for anti-abuse and country detection).',
          ]),
          _card(c, 'What we do NOT collect', [
            'Your video or audio streams — LangLoop uses peer-to-peer WebRTC.',
            'Your location beyond country code.',
            'Your contacts or files.',
          ]),
          _card(c, 'How we use your data', [
            'To match you with other learners.',
            'To compute your XP, streak, and friends list.',
            'To keep the platform safe (report + ban system).',
            'To send you important service emails.',
          ]),
          _card(c, 'Your rights', [
            'You can edit or delete your profile information any time.',
            'You can request a full data export by email.',
            'You can request account deletion — processed within 48 hours.',
          ]),
          _card(c, 'Safety tips', [
            'Never share personal info (address, financial) in a video call.',
            'Use the Report button if someone violates our rules.',
            'We ban accounts immediately after credible reports.',
          ]),
          const SizedBox(height: 20),
          Text(
            'Last updated: ${DateTime.now().year}',
            style: TextStyle(color: c.textSub, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _card(AppColors c, String title, List<String> bullets) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        color: c.textSub,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
