import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _newMatches = true;
  bool _friendRequests = true;
  bool _messages = true;
  bool _streakReminder = true;
  bool _marketing = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(AppIcons.back, color: c.text),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _switchTile('New matches', 'When someone matches with you', _newMatches,
              (v) => setState(() => _newMatches = v)),
          _switchTile('Friend requests', 'When someone wants to be friends',
              _friendRequests, (v) => setState(() => _friendRequests = v)),
          _switchTile('Messages', 'When you receive a new chat message',
              _messages, (v) => setState(() => _messages = v)),
          _switchTile('Streak reminder', 'Daily reminder to keep your streak',
              _streakReminder, (v) => setState(() => _streakReminder = v)),
          _switchTile('Tips & offers', 'Occasional product updates', _marketing,
              (v) => setState(() => _marketing = v)),
        ],
      ),
    );
  }

  Widget _switchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(
            color: c.text,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: c.textSub, fontSize: 12.5),
        ),
        value: value,
        activeThumbColor: c.primary,
        onChanged: onChanged,
      ),
    );
  }
}
