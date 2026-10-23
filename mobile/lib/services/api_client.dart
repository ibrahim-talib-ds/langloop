import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin wrapper around http for talking to the LangLoop backend.
/// Change the base URL when you deploy.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ─── Change this to your production URL later ───
  // For Flutter Web on Chrome: localhost works.
  // For Android emulator: use 10.0.2.2 instead of localhost.
  // For physical device: use your computer's LAN IP.
  String baseUrl = 'https://langloop-backend-2al5.onrender.com/api/v1';

  String? token;

  bool get isLoggedIn => token != null;

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  String _extractMessage(dynamic decoded, int status) {
    if (decoded is Map && decoded['detail'] != null) {
      final detail = decoded['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail[0];
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
        return first.toString();
      }
      if (detail is Map && detail['message'] != null) {
        return detail['message'].toString();
      }
      return detail.toString();
    }
    if (status == 401) return 'Incorrect email or password.';
    if (status == 403) return 'Access denied.';
    if (status == 404) return 'Not found.';
    if (status == 409) return 'That email or username is already taken.';
    if (status == 429) return 'Too many attempts. Please wait a minute.';
    if (status >= 500) return 'Server error. Please try again shortly.';
    return 'Something went wrong (code $status).';
  }

  Map<String, dynamic> _decode(http.Response res) {
    final text = res.body.isEmpty ? '{}' : res.body;
    final decoded = jsonDecode(text);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }
    // error
    final msg = _extractMessage(decoded, res.statusCode);
    throw ApiException(res.statusCode, msg);
  }
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _decode(res);
  }

}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}
