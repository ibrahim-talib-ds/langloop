import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';
import '../widgets/home_widgets.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
        title: const Text('Admin Console'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: c.primary,
          labelColor: c.text,
          unselectedLabelColor: c.textSub,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(text: 'Stats'),
            Tab(text: 'Users'),
            Tab(text: 'Matches'),
            Tab(text: 'Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _StatsTab(),
          _UsersTab(),
          _MatchesTab(),
          _MessagesTab(),
        ],
      ),
    );
  }
}

// ─────────────────────── Stats ───────────────────────
class _StatsTab extends StatefulWidget {
  const _StatsTab();

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _counts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ApiClient.instance.get('/admin/activity/summary');
      final c = await ApiClient.instance.get('/admin/stats');
      if (!mounted) return;
      setState(() {
        _summary = s;
        _counts = c;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }
    if (_counts == null) {
      return Center(
        child: Text(
          'Could not load admin data',
          style: TextStyle(color: c.textSub),
        ),
      );
    }

    final daily = (_summary?['daily'] as List?) ?? [];
    final topUsers = (_summary?['top_users'] as List?) ?? [];

    return RefreshIndicator(
      color: c.primary,
      backgroundColor: c.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Overview ───
          Row(
            children: [
              Expanded(
                child: _bigStat(c, 'Total users', '${_counts!['total_users']}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bigStat(c, 'Active', '${_counts!['active']}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _bigStat(
                  c,
                  'Admins',
                  '${_counts!['admins']}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bigStat(
                  c,
                  'Banned',
                  '${_counts!['banned']}',
                  danger: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ─── Last 14 days ───
          Text(
            'Last 14 days',
            style: TextStyle(
              color: c.text,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                _dailyHeader(c),
                const SizedBox(height: 6),
                ...daily.map((d) => _dailyRow(c, d)),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ─── Top users ───
          Text(
            'Top users by XP',
            style: TextStyle(
              color: c.text,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...topUsers.map((u) => _userCard(c, u)),
        ],
      ),
    );
  }

  Widget _bigStat(AppColors c, String label, String value,
      {bool danger = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: danger ? c.danger : c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: danger ? c.danger : c.text,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: c.textSub, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _dailyHeader(AppColors c) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text('Date',
              style: TextStyle(
                  color: c.textSub, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text('Matches',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: c.textSub, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text('Msgs',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: c.textSub, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text('Users',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: c.textSub, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _dailyRow(AppColors c, dynamic d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              d['date'],
              style: TextStyle(color: c.text, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text('${d['matches']}',
                textAlign: TextAlign.right,
                style: TextStyle(color: c.text, fontSize: 12)),
          ),
          Expanded(
            child: Text('${d['messages']}',
                textAlign: TextAlign.right,
                style: TextStyle(color: c.text, fontSize: 12)),
          ),
          Expanded(
            child: Text('${d['new_users']}',
                textAlign: TextAlign.right,
                style: TextStyle(color: c.text, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _userCard(AppColors c, dynamic u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          AvatarCircle(name: u['username'] ?? '?', size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u['username'] ?? '',
                  style: TextStyle(
                    color: c.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${u['xp']} XP · ${u['total_matches']} matches · ${u['streak_days']}d streak',
                  style: TextStyle(color: c.textSub, fontSize: 11),
                ),
              ],
            ),
          ),
          if (u['is_admin'] == true)
            Icon(AppIcons.verified, color: c.primary, size: 16),
        ],
      ),
    );
  }
}

// ─────────────────────── Users ───────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<dynamic> _users = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_load);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final q = _search.text.trim();
      final res = await ApiClient.instance
          .get('/admin/users${q.isEmpty ? "" : "?q=$q"}');
      final list = res['data'] is List ? res['data'] as List : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _users = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBan(dynamic u) async {
    final banned = u['is_banned'] == true;
    try {
      if (banned) {
        await ApiClient.instance.post('/admin/users/${u['id']}/unban');
      } else {
        await ApiClient.instance.post('/admin/users/${u['id']}/ban',
            body: {'reason': 'Admin action'});
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            style: TextStyle(color: c.text),
            decoration: InputDecoration(
              hintText: 'Search by email or username',
              prefixIcon:
                  Icon(Icons.search_rounded, color: c.textSub, size: 20),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final banned = u['is_banned'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: banned ? c.danger : c.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          AvatarCircle(name: u['username'] ?? '?', size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u['username'] ?? '',
                                  style: TextStyle(
                                    color: c.text,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  u['email'] ?? '',
                                  style: TextStyle(
                                    color: c.textSub,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              banned
                                  ? Icons.lock_open_rounded
                                  : Icons.block_rounded,
                              color: banned ? c.primary : c.danger,
                              size: 20,
                            ),
                            onPressed: () => _toggleBan(u),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────── Matches ───────────────────────
class _MatchesTab extends StatefulWidget {
  const _MatchesTab();

  @override
  State<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<_MatchesTab> {
  List<dynamic> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res =
          await ApiClient.instance.get('/admin/activity/matches?limit=100');
      final list = res['data'] is List ? res['data'] as List : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _matches = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }
    return RefreshIndicator(
      color: c.primary,
      backgroundColor: c.surface,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length,
        itemBuilder: (_, i) {
          final m = _matches[i];
          final dur = m['duration_seconds'] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${m['user_a_username'] ?? "?"} ↔ ${m['user_b_username'] ?? "?"}',
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${dur}s',
                      style: TextStyle(
                        color: c.textSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${m['language']?.toString().toUpperCase()} · ${m['topic']}',
                  style: TextStyle(color: c.textSub, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────── Messages ───────────────────────
class _MessagesTab extends StatefulWidget {
  const _MessagesTab();

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  List<dynamic> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res =
          await ApiClient.instance.get('/admin/activity/messages?limit=100');
      final list = res['data'] is List ? res['data'] as List : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _messages = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }
    return RefreshIndicator(
      color: c.primary,
      backgroundColor: c.surface,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (_, i) {
          final m = _messages[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m['sender_username'] ?? "?"} → ${m['recipient_username'] ?? "?"}',
                  style: TextStyle(
                    color: c.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m['body'] ?? '',
                  style: TextStyle(
                    color: c.textSub,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
