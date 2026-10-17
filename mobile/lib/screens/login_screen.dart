import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/ui_kit.dart';
import '../widgets/google_signin_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.referrerCode});

  final String? referrerCode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        final msg = e.toString();
        // Only show the human-readable part
        _error = msg.length > 200 ? 'Something went wrong. Try again.' : msg;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 8,
              child: CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            Positioned(
              right: 16,
              top: 8,
              child: CircleIconButton(
                icon: isDark
                    ? Icons.wb_sunny_outlined
                    : Icons.dark_mode_outlined,
                onTap: ThemeController.instance.toggle,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 120)),
                      const SizedBox(height: 26),

                      Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign in to access smart, personalized\nlanguage practice made for you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textSub,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 34),

                      const FieldLabel('Email address*'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: c.text),
                        decoration: const InputDecoration(
                          hintText: 'example@gmail.com',
                        ),
                      ),
                      const SizedBox(height: 16),

                      const FieldLabel('Password*'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        style: TextStyle(color: c.text),
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: '@Sn123hsn#',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: c.textSub,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _remember,
                              side: BorderSide(color: c.border),
                              activeColor: c.primary,
                              checkColor: c.primaryFg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onChanged: (v) =>
                                  setState(() => _remember = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: TextStyle(color: c.textSub, fontSize: 13),
                          ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: c.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.danger.withValues(alpha: 0.10),
                              border: Border.all(
                                color: c.danger.withValues(alpha: 0.4),
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded,
                                        color: c.danger, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: c.danger,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_error!.toLowerCase().contains('incorrect'))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _password.text = '';
                                          _error = null;
                                        });
                                      },
                                      child: Text(
                                        'Clear password and try again',
                                        style: TextStyle(
                                          color: c.danger,
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      PillButton(
                        label: 'Sign in',
                        icon: Icons.login_rounded,
                        busy: _busy,
                        onTap: _submit,
                      ),
                      const SizedBox(height: 26),

                      Row(
                        children: [
                          Expanded(child: Divider(color: c.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(color: c.textSub, fontSize: 12),
                            ),
                          ),
                          Expanded(child: Divider(color: c.border)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      GoogleSignInButton(
                        width: 320,
                        onSignedIn: () async {
                          if (!mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 26),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?  ",
                            style: TextStyle(color: c.textSub, fontSize: 13),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => RegisterScreen(
                                          referralCode: widget.referrerCode,
                                        ),
                                      ),
                                    ),
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: c.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
