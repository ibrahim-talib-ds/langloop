import 'package:flutter/material.dart';

/// Wraps an asset PNG (from assets/icons/) with proper sizing, tinting,
/// and a graceful fallback to a Material Icon if the asset is missing.
///
/// Use `size` and optional `color` (if your PNG is a flat mono-color icon).
class AppIconImage extends StatelessWidget {
  const AppIconImage({
    super.key,
    required this.asset,
    this.size = 24,
    this.color,
    this.fallbackIcon,
  });

  /// e.g. 'assets/icons/icon_streak.png'
  final String asset;
  final double size;
  final Color? color;

  /// Shown if the PNG can't be loaded.
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: color != null ? BlendMode.srcIn : null,
        errorBuilder: (_, __, ___) {
          if (fallbackIcon != null) {
            return Icon(
              fallbackIcon,
              size: size,
              color: color ??
                  Theme.of(context).colorScheme.primary,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
