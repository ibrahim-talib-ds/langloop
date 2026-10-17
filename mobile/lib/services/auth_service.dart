import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kToken = 'langloop_token';
  static const _kUser = 'langloop_user';

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => ApiClient.instance.isLoggedIn;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token != null) {
      ApiClient.instance.token = token;
      final u = prefs.getString(_kUser);
      if (u != null) _user = jsonDecode(u) as Map<String, dynamic>;
    }
  }

  Future<void> _persist(String token, Map<String, dynamic> user) async {
    ApiClient.instance.token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user));
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String? referralCode,
  }) async {
    await ApiClient.instance.post('/auth/register', body: {
      'email': email,
      'username': username,
      'password': password,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
    });
    await login(email: email, password: password);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.instance.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final token = res['access_token'] as String;
    ApiClient.instance.token = token;
    final me = await ApiClient.instance.get('/users/me');
    await _persist(token, me);
  }

  Future<void> logout() async {
    ApiClient.instance.token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
  }

  Future<Map<String, dynamic>> fetchStats() =>
      ApiClient.instance.get('/me/stats');

  // ─── Matchmaking ───
  Future<Map<String, dynamic>> joinQueue({
    String language = 'en',
    String topic = 'small_talk',
  }) =>
      ApiClient.instance.post('/match/join', body: {
        'language': language,
        'topic': topic,
      });

  Future<Map<String, dynamic>> matchStatus() =>
      ApiClient.instance.get('/match/status');

  Future<Map<String, dynamic>> leaveQueue() =>
      ApiClient.instance.post('/match/leave');

  Future<Map<String, dynamic>> endMatch(String matchId) =>
      ApiClient.instance.post('/match/$matchId/end');

  Future<Map<String, dynamic>> rateMatch(
    String matchId, {
    required int stars,
    String? comment,
  }) =>
      ApiClient.instance.post('/matches/$matchId/rate', body: {
        'stars': stars,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });

  Future<List<dynamic>> listFriends() async {
    final res = await ApiClient.instance.get('/friends');
    if (res['data'] is List) return res['data'] as List;
    return [];
  }

  /// Used after Google/Apple sign-in — we already have a LangLoop JWT.
  Future<void> loginWithToken(String token) async {
    ApiClient.instance.token = token;
    final me = await ApiClient.instance.get('/users/me');
    await _persist(token, me);
  }


  Future<Map<String, dynamic>> updateMe({
    String? fullName,
    String? bio,
    String? country,
    String? nativeLanguage,
    String? learningLanguage,
    String? level,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (bio != null) body['bio'] = bio;
    if (country != null) body['country'] = country;
    if (nativeLanguage != null) body['native_language'] = nativeLanguage;
    if (learningLanguage != null) body['learning_language'] = learningLanguage;
    if (level != null) body['level'] = level;

    final res = await ApiClient.instance.patch('/users/me', body: body);
    _user = res;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(res));
    return res;
  }


  /// Upload a local file (from image_picker) as the user's avatar.
  Future<Map<String, dynamic>> uploadAvatar(String localPath) async {
    final uri = Uri.parse('${ApiClient.instance.baseUrl}/users/me/avatar');
    final req = http.MultipartRequest('POST', uri);
    if (ApiClient.instance.token != null) {
      req.headers['Authorization'] = 'Bearer ${ApiClient.instance.token}';
    }
    req.files.add(await http.MultipartFile.fromPath('file', localPath));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      _user = decoded;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUser, jsonEncode(decoded));
      return decoded;
    }
    throw Exception('Upload failed (${res.statusCode}): ${res.body}');
  }


  /// Last detected country code (ISO-2) — set by calling detectCountry().
  String? detectedCountry;

  /// Ask the backend to detect the user's country from IP. Silent fail.
  Future<String?> detectCountry() async {
    try {
      final res = await ApiClient.instance.get('/geo/me');
      detectedCountry = res['country'] as String?;
      return detectedCountry;
    } catch (_) {
      return null;
    }
  }


  /// Fetch the current minute-usage summary.
  Future<Map<String, dynamic>> fetchMinutes() =>
      ApiClient.instance.get('/me/minutes');


  /// Add a friend directly (both directions).
  Future<Map<String, dynamic>> addFriend(String otherId) =>
      ApiClient.instance.post('/friends/add/$otherId');


  /// Request a password reset code.
  Future<void> forgotPassword(String email) =>
      ApiClient.instance.post('/auth/forgot-password', body: {
        'email': email,
      }).then((_) {});

  /// Reset password with token.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      ApiClient.instance.post('/auth/reset-password', body: {
        'token': token,
        'new_password': newPassword,
      }).then((_) {});


  /// Send a friend request (not instant).
  Future<Map<String, dynamic>> requestFriend(String otherId) =>
      ApiClient.instance.post('/friends/request/$otherId');

  /// List incoming pending requests.
  Future<List<dynamic>> incomingRequests() async {
    final res = await ApiClient.instance.get('/friends/requests/incoming');
    if (res['data'] is List) return res['data'] as List;
    return [];
  }

  /// List outgoing pending requests.
  Future<List<dynamic>> outgoingRequests() async {
    final res = await ApiClient.instance.get('/friends/requests/outgoing');
    if (res['data'] is List) return res['data'] as List;
    return [];
  }

  /// Accept a request.
  Future<Map<String, dynamic>> acceptRequest(String reqId) =>
      ApiClient.instance.post('/friends/requests/$reqId/accept');

  /// Decline a request.
  Future<Map<String, dynamic>> declineRequest(String reqId) =>
      ApiClient.instance.post('/friends/requests/$reqId/decline');

}
