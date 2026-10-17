import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Global theme mode controller. Wrap the app with ThemeScope
/// to allow reading `context.colors` and toggling mode.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  void setMode(ThemeMode m) {
    _mode = m;
    notifyListeners();
  }

  void toggle() {
    setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Quick access to semantic colors from any widget: context.colors
extension ThemeContextX on BuildContext {
  AppColors get colors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppColors.dark : AppColors.light;
  }
}
