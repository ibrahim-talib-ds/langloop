// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'api_client.dart';

/// Opens Paddle's hosted checkout in a new browser tab.
/// Works on Flutter Web. For mobile we'd use url_launcher + in-app purchase later.
class PaddleService {
  PaddleService._();
  static final PaddleService instance = PaddleService._();

  /// Ask backend for the checkout URL, then open it in a new tab.
  Future<void> openCheckout(String tier) async {
    final res = await ApiClient.instance.post('/billing/checkout', body: {
      'tier': tier,
    });
    final url = res['checkout_url'] as String?;
    if (url == null || url.isEmpty) return;
    html.window.open(url, '_blank');
  }
}
