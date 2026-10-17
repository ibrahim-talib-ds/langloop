import 'dart:js' as js;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

const _webClientId =
    '968349205228-fo3a6mih0msmvbrq1l32e1iirc35e2f3.apps.googleusercontent.com';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onSignedIn,
    this.width = 320,
  });

  final Future<void> Function() onSignedIn;
  final double width;

  Future<void> _handleNative(BuildContext context) async {
    final idToken = await GoogleAuthService.instance.signInNative();
    if (idToken == null) return;
    if (!context.mounted) return;
    await _finish(context, idToken);
  }

  Future<void> _handleWeb(BuildContext context) async {
    js.context.callMethod('eval', [
      """
      window.llGoogleSuccess = function(response) {
        try {
          var token = response.credential;
          window.llGoogleToken = token;
        } catch(e) {
          window.llGoogleToken = null;
        }
      };
      
      if (!window.google || !window.google.accounts) {
         window.llGoogleToken = 'ERROR_SCRIPT';
         return;
      }

      google.accounts.id.initialize({
        client_id: '$_webClientId',
        callback: window.llGoogleSuccess,
        auto_select: false
      });
      
      google.accounts.id.prompt();
      """
    ]);

    // Poll for the token every 500ms (up to 30 seconds)
    String? token;
    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final result = js.context['llGoogleToken'];
      if (result != null) {
        if (result == 'ERROR_SCRIPT') {
           if (context.mounted) _showError(context, 'Google Script not loaded.');
           return;
        }
        token = result as String;
        js.context['llGoogleToken'] = null; // clear it
        break;
      }
    }

    if (!context.mounted) return;
    if (token == null || token.isEmpty) {
      _showError(context, 'Sign-in timed out. Try again.');
      return;
    }
    await _finish(context, token);
  }

  Future<void> _finish(BuildContext context, String idToken) async {
    try {
      final res = await GoogleAuthService.instance.exchangeWithBackend(idToken);
      final token = res['access_token'] as String;
      await AuthService.instance.loginWithToken(token);
      await onSignedIn();
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Google sign-in failed: $e');
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () => kIsWeb ? _handleWeb(context) : _handleNative(context),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleGlyph(size: 20),
                const SizedBox(width: 10),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({super.key, this.size = 18});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4285F4), width: 2),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: const BoxDecoration(
                color: Color(0xFFEA4335),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: size * 0.30,
              height: size * 0.30,
              decoration: const BoxDecoration(
                color: Color(0xFF34A853),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
