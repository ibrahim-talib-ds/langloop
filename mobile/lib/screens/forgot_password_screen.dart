import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_icons.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0=email, 1=code+new password, 2=done
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@') || email.length < 5) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await AuthService.instance.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _step = 1;
        _info = 'If that email exists, a reset code was sent to '
            'your notifications. Enter it below.';
      });
    } catch (e) {
      setState(() => _error = _cleanErr(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the reset code.');
      return;
    }
    if (_newPassword.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.resetPassword(
        token: _code.text.trim(),
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      setState(() {
        _step = 2;
        _info = 'Password updated. You can now sign in.';
      });
    } catch (e) {
      setState(() => _error = _cleanErr(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _cleanErr(Object e) {
    final s = e.toString();
    if (s.length > 200) return 'Something went wrong. Try again.';
    return s;
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
        title: const Text('Reset password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == 2 ? _done(c) : _form(c),
        ),
      ),
    );
  }

  Widget _form(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _step == 0 ? 'Forgot password?' : 'Check your notifications',
          style: TextStyle(
            color: c.text,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _step == 0
              ? 'Enter your email and we\'ll send you a reset code.'
              : 'Enter the reset code we sent and choose a new password.',
          style: TextStyle(color: c.textSub, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        if (_step == 0) ...[
          const _Label('Email address'),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: c.text),
            decoration:
                const InputDecoration(hintText: 'example@gmail.com'),
          ),
        ] else ...[
          const _Label('Reset code'),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            style: TextStyle(color: c.text),
            decoration:
                const InputDecoration(hintText: 'Paste the code here'),
          ),
          const SizedBox(height: 16),
          const _Label('New password'),
          const SizedBox(height: 8),
          TextField(
            controller: _newPassword,
            obscureText: true,
            style: TextStyle(color: c.text),
            decoration:
                const InputDecoration(hintText: 'At least 6 characters'),
          ),
        ],
        const SizedBox(height: 20),

        if (_error != null) _errorBox(c, _error!),
        if (_info != null) _infoBox(c, _info!),

        SizedBox(
          width: double.infinity,
          child: Material(
            color: c.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: _busy
                  ? null
                  : (_step == 0 ? _sendCode : _resetPassword),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: _busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.primaryFg,
                          ),
                        )
                      : Text(
                          _step == 0 ? 'Send code' : 'Reset password',
                          style: TextStyle(
                            color: c.primaryFg,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_step == 1)
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _step = 0;
                      _info = null;
                      _error = null;
                    }),
            child: Text(
              'Use a different email',
              style: TextStyle(color: c.textSub),
            ),
          ),
      ],
    );
  }

  Widget _done(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Icon(Icons.check_circle_rounded, color: c.primary, size: 64),
        const SizedBox(height: 20),
        Text(
          'Password updated',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.text,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'You can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textSub, fontSize: 14),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: c.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => Navigator.maybePop(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Back to sign in',
                    style: TextStyle(
                      color: c.primaryFg,
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
    );
  }

  Widget _errorBox(AppColors c, String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.10),
        border: Border.all(color: c.danger.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: c.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(color: c.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(AppColors c, String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.10),
        border: Border.all(color: c.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: c.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(color: c.text, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      text,
      style: TextStyle(
        color: c.text,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
