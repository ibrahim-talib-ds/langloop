import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';
import '../widgets/home_widgets.dart';
import 'chat_screen.dart';
import 'match_screen.dart';
import 'view_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<dynamic> _friends = [];
  List<dynamic> _filtered = [];
  List<dynamic> _incoming = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AuthService.instance.listFriends();
      final reqs = await AuthService.instance.incomingRequests();
      if (!mounted) return;
      setState(() {
        _friends = list;
        _filtered = list;
        _incoming = reqs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _friends);
      return;
    }
    setState(() {
      _filtered = _friends.where((f) {
        final name = (f['full_name'] ?? '').toString().toLowerCase();
        final user = (f['username'] ?? '').toString().toLowerCase();
        return name.contains(q) || user.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Column(
        children: [
          // ─── Header ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(
                  'Friends',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_friends.length}',
                    style: TextStyle(
                      color: c.primaryFg,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Search ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              style: TextStyle(color: c.text),
              decoration: InputDecoration(
                hintText: 'Search friends',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: c.textSub,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ─── Incoming requests ───
          if (_incoming.isNotEmpty) _buildRequestsBanner(c),

          // ─── Body ───
          Expanded(child: _body(c)),
        ],
      ),
    );
  }

  Widget _buildRequestsBanner(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${_incoming.length}',
                  style: TextStyle(
                    color: c.primaryFg,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Friend request${_incoming.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._incoming.map((req) => _requestCard(c, req)),
        ],
      ),
    );
  }

  Widget _requestCard(AppColors c, dynamic req) {
    final name = (req['from_full_name'] ??
            req['from_username'] ??
            'Someone')
        .toString();
    final reqId = req['id'].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AvatarCircle(
            name: name,
            size: 40,
            imageUrl: req['from_avatar_url'] as String?,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: c.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: c.textSub, size: 20),
            onPressed: () async {
              try {
                await AuthService.instance.declineRequest(reqId);
                await _load();
              } catch (_) {}
            },
          ),
          Material(
            color: c.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () async {
                try {
                  await AuthService.instance.acceptRequest(reqId);
                  await _load();
                } catch (_) {}
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                child: Text(
                  'Accept',
                  style: TextStyle(
                    color: c.primaryFg,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AppColors c) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: c.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: c.danger, size: 40),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSub),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: Text(
                'Retry',
                style: TextStyle(color: c.primary),
              ),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return _emptyState(c);
    }
    return RefreshIndicator(
      color: c.primary,
      backgroundColor: c.surface,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _friendCard(c, _filtered[i]),
      ),
    );
  }

  Widget _emptyState(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surface,
                border: Border.all(color: c.border),
              ),
              child: Icon(
                AppIcons.friends,
                size: 40,
                color: c.textSub,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _friends.isEmpty ? 'No friends yet' : 'No matches',
              style: TextStyle(
                color: c.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _friends.isEmpty
                  ? 'Match with someone, chat, and rate each other 4★ or higher to become friends.'
                  : 'Try a different search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSub,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _friendCard(AppColors c, dynamic f) {
    final name = (f['full_name'] ?? f['username'] ?? 'Unknown').toString();
    final username = (f['username'] ?? '').toString();
    final xp = (f['xp'] as num?)?.toInt() ?? 0;
    final learning = (f['learning_language'] ?? 'en').toString().toUpperCase();
    final online = DateTime.now().second % 3 == 0; // placeholder until presence

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _showActions(context, f),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              AvatarCircle(
                name: name,
                size: 52,
                online: online,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textSub,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _pill(c, AppIcons.xp, '$xp XP'),
                        const SizedBox(width: 8),
                        _pill(c, Icons.language_rounded, learning),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: c.textSub,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(AppColors c, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: c.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context, dynamic f) {
    final c = context.colors;
    final name = (f['full_name'] ?? f['username'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              AvatarCircle(name: name, size: 72, online: true),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                  color: c.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${f['username']}',
                style: TextStyle(color: c.textSub, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _actionTile(
                context,
                AppIcons.video,
                'Start a video round',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MatchScreen(topic: 'small_talk'),
                    ),
                  );
                },
              ),
              _actionTile(context, Icons.chat_bubble_outline_rounded,
                  'Send a message', onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherId: f['id'].toString(),
                        otherName: (f['full_name'] ?? f['username'] ?? '').toString(),
                      ),
                    ),
                  );
                }),
              _actionTile(
                context,
                AppIcons.profile,
                'View profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ViewProfileScreen(
                        userId: f['id'].toString(),
                        userName: (f['full_name'] ?? f['username'] ?? '')
                            .toString(),
                      ),
                    ),
                  );
                },
              ),
              _actionTile(context, AppIcons.report, 'Report user',
                  danger: true, onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool danger = false,
  }) {
    final c = context.colors;
    final color = danger ? c.danger : c.text;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color: c.textSub,
      ),
      onTap: onTap,
    );
  }
}
