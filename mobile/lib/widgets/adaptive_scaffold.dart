import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'app_icon_image.dart';
import 'app_icons.dart';

/// Wraps the app's tab pages. Renders:
///   - Side navigation rail on desktop/tablet (width ≥ 900)
///   - Bottom pill nav on phone (width < 900)
///   - Content is width-capped so text doesn't sprawl
String? _assetFor(IconData icon) {
  if (icon == AppIcons.home) return 'assets/icons/icon_home.png';
  if (icon == AppIcons.friends) return 'assets/icons/icon_friends.png';
  if (icon == AppIcons.profile) return 'assets/icons/icon_profile.png';
  return null;
}

class AdaptiveScaffold extends StatelessWidget {

  const AdaptiveScaffold({
    super.key,
    required this.index,
    required this.onChange,
    required this.children,
  });

  final int index;
  final ValueChanged<int> onChange;
  final List<Widget> children;

  static const _items = <(IconData, String)>[
    (AppIcons.home, 'Home'),
    (AppIcons.friends, 'Friends'),
    (AppIcons.profile, 'Profile'),
  ];

  static bool isWide(BuildContext c) =>
      MediaQuery.of(c).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _SideRail(index: index, onChange: onChange, items: _items),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: IndexedStack(index: index, children: children),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: index, children: children),
      bottomNavigationBar: _BottomPillNav(
        index: index,
        onChange: onChange,
        items: _items,
      ),
    );
  }
}

// ─────────────────────────── Side rail ───────────────────────────
class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.index,
    required this.onChange,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onChange;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          right: BorderSide(color: c.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Logo + title ───
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
              child: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: c.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'LangLoop',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            const SizedBox(height: 14),

            // ─── Nav items ───
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final (icon, label) = entry.value;
              final selected = i == index;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                child: Material(
                  color: selected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => onChange(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          AppIconImage(
                            asset: _assetFor(icon) ?? '',
                            size: 20,
                            color: selected ? c.primaryFg : c.textSub,
                            fallbackIcon: icon,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            label,
                            style: TextStyle(
                              color: selected ? c.primaryFg : c.text,
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            // ─── Footer ───
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'v1.0.0',
                style: TextStyle(color: c.textSub, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Bottom pill nav ───────────────────────────
class _BottomPillNav extends StatelessWidget {
  const _BottomPillNav({
    required this.index,
    required this.onChange,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onChange;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final (icon, label) = entry.value;
            final selected = i == index;
            return Expanded(
              child: Material(
                color: selected ? c.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => onChange(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIconImage(
                          asset: _assetFor(icon) ?? '',
                          size: 18,
                          color: selected ? c.primaryFg : c.textSub,
                          fallbackIcon: icon,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              color: c.primaryFg,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
