import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/ui_kit.dart';
import '../widgets/google_signin_button.dart';
import 'home_screen.dart';
import '../widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.referralCode});

  final String? referralCode;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.register(
        email: _email.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim(),
        referralCode: widget.referralCode,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      setState(() {
        final msg = e.toString();
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
                      const Center(child: AppLogo(size: 110)),
                      const SizedBox(height: 22),
                      Text(
                        'Create Your Account',
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
                        'Create your account to explore exciting\nlanguage practice sessions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textSub,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 30),

                      if (widget.referralCode != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [c.primary, c.primary.withValues(alpha: 0.5)],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.card_giftcard_rounded, color: c.primaryFg, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You were invited! Both of you will get 30 bonus minutes and become friends.',
                                  style: TextStyle(color: c.primaryFg, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const FieldLabel('Full Name*'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fullName,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: c.text),
                        decoration:
                            const InputDecoration(hintText: 'Alex Smith'),
                      ),
                      const SizedBox(height: 16),

                      const FieldLabel('Username*'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _username,
                        style: TextStyle(color: c.text),
                        decoration:
                            const InputDecoration(hintText: 'alexsmith'),
                      ),
                      const SizedBox(height: 16),

                      const FieldLabel('Email address*'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: c.text),
                        decoration: const InputDecoration(
                            hintText: 'example@gmail.com'),
                      ),
                      const SizedBox(height: 16),

                      const FieldLabel('Password*'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        style: TextStyle(color: c.text),
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
                      const SizedBox(height: 24),

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
                            child: Text(
                              _error!,
                              style: TextStyle(color: c.danger, fontSize: 13),
                            ),
                          ),
                        ),

                      PillButton(
                        label: 'Register',
                        icon: Icons.person_add_alt_1_rounded,
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
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                            (_) => false,
                          );
                        },
                      ),
                      const SizedBox(height: 26),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?  ',
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
                                : () => Navigator.maybePop(context),
                            child: Text(
                              'Sign In',
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
