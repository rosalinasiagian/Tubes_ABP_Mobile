import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:godone/main.dart';
import 'package:godone/services/api_service.dart';

void main() {
  testWidgets('shows login screen when no session is stored',
      (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await ApiService.loadToken();

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
