import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flipoff/game/auth_gateway_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthGatewayPage Widget Tests', () {
    testWidgets('Renders Google Sign-In and Continue as Guest options', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthGatewayPage(),
        ),
      );

      // Verify title branding and subtitle exist
      expect(find.text('FlippOff'), findsOneWidget);
      expect(find.text('AUTHENTICATION GATEWAY'), findsOneWidget);

      // Verify Google Sign-In button exists
      expect(find.text('Sign in with Google'), findsOneWidget);

      // Verify Continue as Guest text button exists
      expect(find.text('Continue as Guest'), findsOneWidget);
    });
  });
}
