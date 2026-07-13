import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flipoff/game/models/user_profile.dart';
import 'package:flipoff/game/services/user_profile_service.dart';
import 'package:flipoff/game/lobby_page.dart';
import 'package:flipoff/game/locker_page.dart';
import 'package:flipoff/game/shop_overlay.dart';
import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final service = UserProfileService.instance;
    service.authInstance = FakeFirebaseAuth();
    service.firestoreInstance = FakeFirebaseFirestore();
    service.mockUserId = 'mock_uid_abc';
  });

  group('User Workflow Widget Tests', () {
    testWidgets('LobbyPage displays correct token and dust balances', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await UserProfileService.instance.initialize();
      const testProfile = UserProfile(
        dailyFreeGames: 2,
        tokenCount: 42,
        glowDustCount: 150,
      );
      await UserProfileService.instance.saveProfile(testProfile);

      await tester.pumpWidget(
        const MaterialApp(
          home: LobbyPage(),
        ),
      );

      // Verify balances are displayed
      expect(find.textContaining('TOKENS: 42'), findsOneWidget);
      expect(find.textContaining('Free: 2'), findsOneWidget);
      expect(find.textContaining('DUST: 150'), findsOneWidget);
    });

    testWidgets('LockerPage displays locked/active skin states', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await UserProfileService.instance.initialize();
      const testProfile = UserProfile(
        glowDustCount: 50,
        unlockedSkins: ['ball_default', 'flipper_default'],
        activeBallSkin: 'ball_default',
      );
      await UserProfileService.instance.saveProfile(testProfile);

      await tester.pumpWidget(
        const MaterialApp(
          home: LockerPage(),
        ),
      );

      // Verify skin names exist
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('Neon Purple'), findsOneWidget);

      // Verify first default is ACTIVE, second is Locked (shows cost 100)
      expect(find.text('ACTIVE'), findsNWidgets(2)); // Chrome + Original Purple
      expect(find.text('100'), findsOneWidget); // cost for Neon Purple ball skin
    });

    testWidgets('ShopOverlay displays item options', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await UserProfileService.instance.initialize();
      const testProfile = UserProfile(tokenCount: 10, dailyFreeGames: 3);
      await UserProfileService.instance.saveProfile(testProfile);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShopOverlay(),
          ),
        ),
      );

      // Check title and item options
      expect(find.text('CREDITS SHOP'), findsOneWidget);
      expect(find.text('WATCH REWARDED AD'), findsOneWidget);
      expect(find.text('INFINITE PLAY PASS'), findsOneWidget);
      expect(find.text('25 GLOW TOKENS PACK'), findsOneWidget);
    });
  });
}
