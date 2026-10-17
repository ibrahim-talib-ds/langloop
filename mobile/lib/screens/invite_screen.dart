import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.get('/referrals/me');
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.surface,
      ),
    );
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
        title: const Text('Invite a friend'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Hero card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        c.primary,
                        c.primary.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        color: c.primaryFg,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Get 30 free minutes',
                        style: TextStyle(
                          color: c.primaryFg,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share LangLoop with a friend. When they sign up '
                        'with your code, you BOTH get 30 bonus minutes of '
                        'practice — on top of your daily limit.',
                        style: TextStyle(
                          color: c.primaryFg.withValues(alpha: 0.85),
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats
                if (_data != null)
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          c,
                          'Your code',
                          _data!['code'] ?? '—',
                          copyable: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          c,
                          'Bonus minutes',
                          '${_data!['bonus_minutes'] ?? 0}',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Share button
                if (_data != null) ...[
                  _copyField(
                    c,
                    'Share link',
                    _buildShareLink(),
                    onCopy: () => _copy(_buildShareLink(), 'Link'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () => _copy(_buildShareLink(), 'Link'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share_rounded,
                                  color: c.primaryFg, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Copy & share link',
                                style: TextStyle(
                                  color: c.primaryFg,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // How it works
                Container(
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
                        'How it works',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _step(c, '1', 'Share your unique link with a friend'),
                      _step(c, '2', 'They sign up and enter your code'),
                      _step(c, '3',
                          'You BOTH get 30 bonus minutes instantly'),
                      _step(c, '4', 'Stack as many invites as you want'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _buildShareLink() {
    final code = _data?['code'] as String? ?? '';
    if (code.isEmpty) return '';
    // Use the current browser origin (works on localhost and deployed)
    final origin = Uri.base.origin;
    return '$origin/?ref=$code';
  }

  Widget _statCard(AppColors c, String label, String value,
      {bool copyable = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: c.textSub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (copyable)
                Icon(Icons.copy_rounded, size: 14, color: c.textSub),
            ],
          ),
        ],
      ),
    );
  }

  Widget _copyField(
    AppColors c,
    String label,
    String value, {
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: c.textSub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, color: c.primary, size: 18),
                onPressed: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _step(AppColors c, String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: c.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  color: c.primaryFg,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: c.text, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
