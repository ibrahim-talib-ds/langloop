import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/paddle_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  String _currentTier = 'free';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.get('/billing/me');
      if (!mounted) return;
      setState(() => _currentTier = res['tier'] as String? ?? 'free');
    } catch (_) {}
  }

  Future<void> _choose(String tier) async {
    setState(() => _busy = true);
    try {
      await PaddleService.instance.openCheckout(tier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete payment in the new tab. '
            'Come back here after and pull to refresh.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open checkout: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surface,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
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
        title: const Text('Upgrade'),
      ),
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Unlock unlimited practice',
              style: TextStyle(
                color: c.text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Free users get 10 minutes of practice per day. '
              'Upgrade for unlimited rounds and premium features.',
              style: TextStyle(color: c.textSub, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 24),

            _planCard(
              c,
              name: 'Plus',
              price: '\$4.99',
              period: '/month',
              features: const [
                'Unlimited video rounds',
                'No ads',
                'Save friends after chats',
                'Language filter',
              ],
              tier: 'plus',
            ),
            const SizedBox(height: 14),
            _planCard(
              c,
              name: 'Pro',
              price: '\$9.99',
              period: '/month',
              features: const [
                'Everything in Plus',
                'Priority matching',
                'Topic filter',
                'Streak protection',
                'Early access to new features',
              ],
              tier: 'pro',
              recommended: true,
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, size: 16, color: c.textSub),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Secure checkout via Paddle. Cancel anytime. '
                      'Current plan: ${_currentTier.toUpperCase()}',
                      style: TextStyle(
                        color: c.textSub,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(
    AppColors c, {
    required String name,
    required String price,
    required String period,
    required List<String> features,
    required String tier,
    bool recommended = false,
  }) {
    final isCurrent = _currentTier == tier;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isCurrent
              ? c.primary
              : recommended
                  ? c.primary.withValues(alpha: 0.5)
                  : c.border,
          width: isCurrent ? 2 : 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: TextStyle(
                  color: c.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              if (recommended && !isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'POPULAR',
                    style: TextStyle(
                      color: c.primaryFg,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                price,
                style: TextStyle(
                  color: c.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                period,
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_rounded,
                        size: 16, color: c.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: isCurrent ? c.border : c.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: isCurrent || _busy
                    ? null
                    : () => _choose(tier),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _busy && !isCurrent
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.primaryFg,
                            ),
                          )
                        : Text(
                            isCurrent ? 'Current plan' : 'Choose $name',
                            style: TextStyle(
                              color: isCurrent ? c.textSub : c.primaryFg,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
