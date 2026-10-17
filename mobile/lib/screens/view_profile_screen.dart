import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';
import '../widgets/home_widgets.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.get('/admin/users/${widget.userId}');
      if (!mounted) return;
      setState(() {
        _user = res;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(AppIcons.back, color: c.text),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Profile'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : _user == null
              ? Center(
                  child: Text(
                    'Could not load profile',
                    style: TextStyle(color: c.textSub),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AvatarCircle(
                        name: widget.userName,
                        size: 100,
                        imageUrl: _user!['avatar_url'] as String?,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.userName,
                        style: TextStyle(
                          color: c.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${_user!['username']}',
                        style: TextStyle(color: c.textSub, fontSize: 13),
                      ),
                      if ((_user!['bio'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: c.border),
                          ),
                          child: Text(
                            _user!['bio'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat(c, 'XP', '${_user!['xp'] ?? 0}'),
                            _stat(c, 'Streak',
                                '${_user!['streak_days'] ?? 0}d'),
                            _stat(c, 'Matches',
                                '${_user!['total_matches'] ?? 0}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _stat(AppColors c, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: c.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: c.textSub, fontSize: 12)),
      ],
    );
  }
}
