// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js' as js;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

const _webClientId =
    '968349205228-fo3a6mih0msmvbrq1l32e1iirc35e2f3.apps.googleusercontent.com';

bool _gsiInitialized = false;

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
    if (!_gsiInitialized) {
      js.context.callMethod('eval', [
        r"""
        window.__llGoogleResolvers = [];
        window.llGoogleCallback = function(response) {
          try {
            var token = response && response.credential ? response.credential : null;
            var r = window.__llGoogleResolvers.shift();
            if (r) r(token);
          } catch (e) {
            var r = window.__llGoogleResolvers.shift();
            if (r) r(null);
          }
        };
        if (window.google && window.google.accounts) {
          google.accounts.id.initialize({
            client_id: '""" + _webClientId + r"""',
            callback: window.llGoogleCallback,
            auto_select: false,
            cancel_on_tap_outside: true,
            use_fedcm_for_prompt: true
          });
          window.__llGsiReady = true;
        } else {
          window.__llGsiReady = false;
        }
        """,
      ]);
      _gsiInitialized = true;
    }

    final ready = js.context['__llGsiReady'] == true;
    if (!ready) {
      if (!context.mounted) return;
      _snack(
        context,
        'Google Sign-In script not loaded. Refresh the page and try again.',
      );
      return;
    }

    js.context.callMethod('eval', [
      """
      window.__llGooglePromise = new Promise(function(resolve) {
        window.__llGoogleResolvers.push(resolve);
      });
      google.accounts.id.prompt();
      """,
    ]);

    final completer = Completer<String?>();
    Timer(const Duration(seconds: 25), () {
      if (!completer.isCompleted) completer.complete(null);
    });

    Timer.periodic(const Duration(milliseconds: 300), (t) async {
      if (completer.isCompleted) {
        t.cancel();
        return;
      }
      final result = js.context['__llLastCredential'];
      if (result != null && result is String && result.isNotEmpty) {
        js.context['__llLastCredential'] = null;
        if (!completer.isCompleted) completer.complete(result);
        t.cancel();
      }
    });

    final token = await completer.future;
    if (!context.mounted) return;
    if (token == null) {
      _snack(
        context,
        'Google Sign-In did not complete. Make sure you\'re signed into '
        'Google in another tab, then try again.',
      );
      return;
    }
    await _finish(context, token);
  }

  Future<void> _finish(BuildContext context, String idToken) async {
    try {
      final res =
          await GoogleAuthService.instance.exchangeWithBackend(idToken);
      final token = res['access_token'] as String;
      await AuthService.instance.loginWithToken(token);
      await onSignedIn();
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Google sign-in failed: $e');
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.surface,
        duration: const Duration(seconds: 5),
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
