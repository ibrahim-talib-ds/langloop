import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/app_icon_image.dart';
import '../widgets/app_icons.dart';
import '../widgets/home_widgets.dart';
import 'friends_screen.dart';
import 'match_screen.dart';
import 'profile_screen.dart';
import 'view_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _minutes;
  List<dynamic> _friends = [];
  String _selectedTopic = 'small_talk';

  static const _topics = <(String, String, IconData)>[
    ('small_talk', 'Small talk', AppIcons.topicChat),
    ('interview', 'Interview', AppIcons.topicJob),
    ('travel', 'Travel', AppIcons.topicTrip),
    ('food', 'Food', AppIcons.topicFood),
    ('tech', 'Tech', AppIcons.topicTech),
    ('daily_life', 'Daily life', AppIcons.topicLife),
    ('gaming', 'Gaming', AppIcons.topicGame),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await AuthService.instance.fetchStats();
      final m = await AuthService.instance.fetchMinutes();
      final f = await AuthService.instance.listFriends();
      if (mounted) {
        setState(() {
          _stats = s;
          _minutes = m;
          _friends = f;
        });
      }
    } catch (_) {}
  }

  void _startMatch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchScreen(topic: _selectedTopic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      index: _navIndex,
      onChange: (i) => setState(() => _navIndex = i),
      children: [
        _buildHomeTab(),
        const FriendsScreen(),
        const ProfileScreen(),
      ],
    );
  }

  Widget _buildHomeTab() {
    final wide = AdaptiveScaffold.isWide(context);
    return RefreshIndicator(
      color: context.colors.primary,
      backgroundColor: context.colors.surface,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(wide ? 40 : 20, 24, wide ? 40 : 20, 30),
        child: wide ? _desktopLayout() : _phoneLayout(),
      ),
    );
  }

  // ───────────────────────── HEADER ─────────────────────────
  Widget _header() {
    final c = context.colors;
    final u = AuthService.instance.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = (u?['full_name'] as String?)?.trim().isNotEmpty == true
        ? u!['full_name'] as String
        : (u?['username'] as String? ?? 'Friend');
    final firstName = name.split(' ').first;

    return Row(
      children: [
        AvatarCircle(
          name: name,
          size: 46,
          online: true,
          imageUrl: u?['avatar_url'] as String?,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                firstName,
                style: TextStyle(
                  color: c.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        _MinutesBadge(minutes: _minutes),
        const SizedBox(width: 8),
        StreakPill(days: _stats?['streak_days'] ?? 0),
        const SizedBox(width: 8),
        _IconButton(
          icon: isDark ? AppIcons.sun : AppIcons.moon,
          onTap: ThemeController.instance.toggle,
        ),
      ],
    );
  }

  // ───────────────────────── PHONE LAYOUT ─────────────────────────
  Widget _phoneLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 22),
        if (_stats != null) _xpBar(),
        const SizedBox(height: 18),
        _statsRow(),
        const SizedBox(height: 28),
        Center(child: MatchNowButton(onTap: _startMatch)),
        const SizedBox(height: 28),
        SectionHeader(title: 'Pick a topic'),
        const SizedBox(height: 4),
        _topicChips(),
        const SizedBox(height: 26),
        _friendsSection(),
      ],
    );
  }

  // ───────────────────────── DESKTOP / TABLET LAYOUT ─────────────────────────
  Widget _desktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column — stats + topics
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_stats != null) _xpBar(),
                  const SizedBox(height: 16),
                  _statsRow(),
                  const SizedBox(height: 24),
                  SectionHeader(title: 'Pick a topic'),
                  const SizedBox(height: 8),
                  _topicChips(),
                  const SizedBox(height: 24),
                  _friendsSection(),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right column — big CTA card
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Ready to practice?',
                      style: TextStyle(
                        color: context.colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Meet a stranger, speak for 5 minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.colors.textSub,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 26),
                    MatchNowButton(onTap: _startMatch),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────── SHARED COMPONENTS ─────────────────────────

  Widget _xpBar() {
    return XpBar(
      level: _stats!['level'] ?? 1,
      xp: _stats!['xp'] ?? 0,
      nextXp: _stats!['next_xp'] as int?,
      progress: _stats!['progress'] ?? 0,
    );
  }

  Widget _statsRow() {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statTile(
              icon: Icons.bolt_rounded,
              value: '${_stats?['xp'] ?? 0}',
              label: 'XP',
              color: const Color(0xFFFFB800),
              imageAsset: 'assets/icons/icon_xp.png',
            ),
          ),
          _divider(),
          Expanded(
            child: _statTile(
              icon: Icons.local_fire_department_rounded,
              value: '${_stats?['streak_days'] ?? 0}d',
              label: 'STREAK',
              color: const Color(0xFFFF6B4A),
              imageAsset: 'assets/icons/icon_streak.png',
            ),
          ),
          _divider(),
          Expanded(
            child: _statTile(
              icon: Icons.emoji_events_rounded,
              value: '${_stats?['total_matches'] ?? 0}',
              label: 'MATCHES',
              color: c.primary,
              imageAsset: 'assets/icons/icon_trophy.png',
            ),
          ),
          _divider(),
          Expanded(
            child: _statTile(
              icon: Icons.people_alt_rounded,
              value: '${_stats?['friend_count'] ?? 0}',
              label: 'FRIENDS',
              color: const Color(0xFF7C5CFF),
              imageAsset: 'assets/icons/icon_friends.png',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    String? imageAsset,
  }) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: imageAsset != null
              ? AppIconImage(
                  asset: imageAsset,
                  size: 24,
                  color: color,
                  fallbackIcon: icon,
                )
              : Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: c.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: c.textSub,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 50,
        color: context.colors.border,
      );

  Widget _topicChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _topics
          .map(
            (t) => TopicChip(
              icon: t.$3,
              label: t.$2,
              selected: _selectedTopic == t.$1,
              onTap: () => setState(() => _selectedTopic = t.$1),
            ),
          )
          .toList(),
    );
  }

  Widget _friendsSection() {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Your circle',
          action: TextButton(
            onPressed: () => setState(() => _navIndex = 1),
            child: Text(
              'See all',
              style: TextStyle(
                color: c.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(height: 92, child: _friendsPreview()),
      ],
    );
  }

  Widget _friendsPreview() {
    final c = context.colors;
    if (_friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Match with someone and rate them 4★ or higher to become friends.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textSub,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _friends.length,
      itemBuilder: (_, i) {
        final f = _friends[i];
        final name = (f['full_name'] ?? f['username'] ?? 'Friend').toString();
        return _FriendTile(
          name: name,
          online: true,
          avatarUrl: f['avatar_url'] as String?,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ViewProfileScreen(
                userId: f['id'].toString(),
                userName: name,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.name,
    required this.online,
    this.avatarUrl,
    this.onTap,
  });
  final String name;
  final bool online;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: SizedBox(
            width: 68,
            child: Column(
              children: [
                AvatarCircle(
                  name: name,
                  size: 54,
                  online: online,
                  imageUrl: avatarUrl,
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
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
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.border),
            color: c.surface.withValues(alpha: 0.6),
          ),
          child: Icon(icon, size: 18, color: c.text),
        ),
      ),
    );
  }
}

class _MinutesBadge extends StatelessWidget {
  const _MinutesBadge({this.minutes});
  final Map<String, dynamic>? minutes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unlimited = minutes?['unlimited'] == true;
    final remaining = minutes?['remaining'];
    final exhausted = minutes?['is_exhausted'] == true;

    final text = unlimited
        ? '∞'
        : (remaining != null ? '${remaining}m' : '—');

    final color = exhausted
        ? c.danger
        : unlimited
            ? c.primary
            : c.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: exhausted
              ? c.danger
              : unlimited
                  ? c.primary
                  : c.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unlimited)
            Icon(Icons.all_inclusive_rounded, size: 14, color: color)
          else
            AppIconImage(
              asset: 'assets/icons/icon_clock.png',
              size: 14,
              color: color,
              fallbackIcon: Icons.timer_outlined,
            ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
