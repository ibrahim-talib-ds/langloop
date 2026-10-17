import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/app_icon_image.dart';
import '../widgets/app_icons.dart';
import '../widgets/home_widgets.dart';
import 'admin_console_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'invite_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'upgrade_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await AuthService.instance.fetchStats();
      if (!mounted) return;
      setState(() {
        _stats = s;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Log out?',
          style: TextStyle(
            color: context.colors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'You can sign back in any time.',
          style: TextStyle(color: context.colors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.textSub),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Log out',
              style: TextStyle(color: context.colors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (updated == true) {
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Delete your account?',
          style: TextStyle(
            color: context.colors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This will permanently remove your profile, matches, messages, '
          'and friends. This action cannot be undone.',
          style: TextStyle(color: context.colors.textSub, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.textSub),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: context.colors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.instance.delete('/users/me');
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = AdaptiveScaffold.isWide(context);

    return RefreshIndicator(
      color: context.colors.primary,
      backgroundColor: context.colors.surface,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          wide ? 40 : 20,
          24,
          wide ? 40 : 20,
          30,
        ),
        child: wide ? _desktopLayout(context) : _mobileLayout(context),
      ),
    );
  }

  // ──────────────────────────────── MOBILE LAYOUT ────────────────────────────────
  Widget _mobileLayout(BuildContext context) {
    final c = context.colors;
    final u = AuthService.instance.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          'Profile',
          style: TextStyle(
            color: c.text,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 22),

        _avatarCard(c, u),
        const SizedBox(height: 16),
        _statsGrid(c),
        const SizedBox(height: 24),

        _settingsSection(c),
      ],
    );
  }

  // ──────────────────────────────── DESKTOP LAYOUT ────────────────────────────────
  Widget _desktopLayout(BuildContext context) {
    final c = context.colors;
    final u = AuthService.instance.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Text(
          'Profile',
          style: TextStyle(
            color: c.text,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 28),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left — avatar + stats
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _avatarCard(c, u),
                  const SizedBox(height: 20),
                  _statsGrid(c),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right — settings
            Expanded(
              flex: 5,
              child: _settingsSection(c),
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────── SHARED COMPONENTS ────────────────────────────────
  Widget _avatarCard(AppColors c, Map<String, dynamic>? u) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          AvatarCircle(
            name: (u?['full_name'] ?? u?['username'] ?? 'You').toString(),
            size: 100,
            online: true,
            verified: (u?['is_admin'] as bool?) == true,
            imageUrl: u?['avatar_url'] as String?,
          ),
          const SizedBox(height: 16),
          Text(
            (u?['full_name'] as String?)?.isNotEmpty == true
                ? u!['full_name']
                : (u?['username'] ?? 'Unknown'),
            style: TextStyle(
              color: c.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${u?['username'] ?? ''}',
            style: TextStyle(color: c.textSub, fontSize: 13),
          ),
          if ((u?['bio'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                u!['bio'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(c, Icons.language_rounded,
                  'Native ${(u?['native_language'] ?? 'en').toString().toUpperCase()}'),
              const SizedBox(width: 8),
              _chip(c, Icons.school_rounded,
                  'Learning ${(u?['learning_language'] ?? 'en').toString().toUpperCase()}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(AppColors c) {
    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(color: c.primary),
        ),
      );
    }
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                c,
                Icons.bolt_rounded,
                'LEVEL ${_stats!['level']}',
                '${_stats!['badge'] ?? ''} ${_stats!['title'] ?? ''}',
                accent: true,
                imageAsset: 'assets/icons/icon_xp.png',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                c,
                Icons.local_fire_department_rounded,
                '${_stats!['streak_days']} days',
                'Streak',
                imageAsset: 'assets/icons/icon_streak.png',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                c,
                Icons.emoji_events_rounded,
                '${_stats!['total_matches']}',
                'Matches',
                imageAsset: 'assets/icons/icon_trophy.png',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                c,
                Icons.people_alt_rounded,
                '${_stats!['friend_count']}',
                'Friends',
                imageAsset: 'assets/icons/icon_friends.png',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _settingsSection(AppColors c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final u = AuthService.instance.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            color: c.text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),

        if ((u?['is_admin'] as bool?) == true)
          _settingsTile(
            context,
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin Console',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminConsoleScreen()),
            ),
          ),
        _settingsTile(
          context,
          icon: Icons.card_giftcard_rounded,
          label: 'Invite a friend, get free minutes',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InviteScreen()),
          ),
        ),
        _settingsTile(
          context,
          icon: Icons.workspace_premium_rounded,
          label: 'Upgrade to Plus or Pro',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UpgradeScreen()),
          ),
        ),
        _settingsTile(
          context,
          icon: Icons.edit_rounded,
          label: 'Edit profile',
          onTap: _editProfile,
        ),
        _settingsTile(
          context,
          icon: isDark ? AppIcons.sun : AppIcons.moon,
          label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onTap: ThemeController.instance.toggle,
        ),
        _settingsTile(
          context,
          icon: Icons.notifications_none_rounded,
          label: 'Notifications',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        _settingsTile(
          context,
          icon: Icons.shield_outlined,
          label: 'Privacy & safety',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyScreen()),
          ),
        ),
        _settingsTile(
          context,
          icon: Icons.help_outline_rounded,
          label: 'Help & support',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HelpScreen()),
          ),
        ),
        _settingsTile(
          context,
          icon: Icons.delete_forever_rounded,
          label: 'Delete my account',
          danger: true,
          onTap: _deleteAccount,
        ),
        _settingsTile(
          context,
          icon: AppIcons.logout,
          label: 'Log out',
          danger: true,
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _chip(AppColors c, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: c.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    AppColors c,
    IconData icon,
    String value,
    String label, {
    bool accent = false,
    String? imageAsset,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ? c.primary : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent ? c.primary : c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageAsset != null
              ? AppIconImage(
                  asset: imageAsset,
                  size: 22,
                  color: accent ? c.primaryFg : c.primary,
                  fallbackIcon: icon,
                )
              : Icon(
                  icon,
                  size: 22,
                  color: accent ? c.primaryFg : c.primary,
                ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: accent ? c.primaryFg : c.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: accent
                  ? c.primaryFg.withValues(alpha: 0.75)
                  : c.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: danger ? c.danger : c.text,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: danger ? c.danger : c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: c.textSub,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
