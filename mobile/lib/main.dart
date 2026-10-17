import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

String? _initialReferralCode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse referral code from URL (?ref=CODE)
  final params = Uri.base.queryParameters;
  _initialReferralCode = params['ref'];

  await AuthService.instance.restore();
  // ignore: unawaited_futures
  AuthService.instance.detectCountry();
  runApp(const LangLoopApp());
}

class LangLoopApp extends StatelessWidget {
  const LangLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeController.instance;
    return AnimatedBuilder(
      animation: tc,
      builder: (_, __) {
        return MaterialApp(
          title: 'LangLoop',
          debugShowCheckedModeBanner: false,
          themeMode: tc.mode,
          theme: AppTheme.build(AppColors.light, Brightness.light),
          darkTheme: AppTheme.build(AppColors.dark, Brightness.dark),
          home: AuthService.instance.isLoggedIn
              ? const HomeScreen()
              : LoginScreen(referrerCode: _initialReferralCode),
        );
      },
    );
  }
}
