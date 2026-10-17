import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';

/// Cross-platform Google Sign-In.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  static const String webClientId =
      '968349205228-fo3a6mih0msmvbrq1l32e1iirc35e2f3.apps.googleusercontent.com';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    await GoogleSignIn.instance.initialize(
      clientId: null,
      serverClientId: webClientId,
    );
    _initialized = true;
  }

  Future<String?> signInNative() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      // In google_sign_in 7.x, `authentication` is a getter, not a Future.
      final auth = account.authentication;
      return auth.idToken;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> exchangeWithBackend(String idToken) async {
    return ApiClient.instance.post('/auth/google', body: {
      'id_token': idToken,
    });
  }
}
