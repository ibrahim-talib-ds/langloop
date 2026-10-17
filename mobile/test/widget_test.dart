import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:langloop_app/theme/app_theme.dart';

void main() {
  testWidgets('App theme builds without crashing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(AppColors.dark, Brightness.dark),
        home: const Scaffold(body: Text('test')),
      ),
    );
    expect(find.text('test'), findsOneWidget);
  });
}
