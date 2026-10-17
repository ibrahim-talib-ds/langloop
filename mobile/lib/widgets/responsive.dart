import 'package:flutter/material.dart';

/// Breakpoints:
///   < 600  → phone
///   600–1000 → tablet
///   > 1000 → desktop
class Breakpoints {
  static const phone = 600.0;
  static const tablet = 1000.0;

  static bool isPhone(BuildContext c) =>
      MediaQuery.of(c).size.width < phone;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    return w >= phone && w < tablet;
  }
  static bool isDesktop(BuildContext c) =>
      MediaQuery.of(c).size.width >= tablet;
}

/// Wrap content so it stays centered and readable on wide screens.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Same as above but for content that should NOT scroll (chat, video).
class ResponsiveCenterFill extends StatelessWidget {
  const ResponsiveCenterFill({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
