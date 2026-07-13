import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flipoff/game/models/user_profile.dart';
import 'package:flipoff/game/services/user_profile_service.dart';
import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfile Model Tests', () {
    test('Constructor and JSON serialization', () {
      const profile = UserProfile(
        dailyFreeGames: 2,
        tokenCount: 10,
        glowDustCount: 50,
      );

      expect(profile.dailyFreeGames, 2);
      expect(profile.tokenCount, 10);
      expect(profile.glowDustCount, 50);

      final json = profile.toJson();
      final fromJson = UserProfile.fromJson(json);

      expect(fromJson.dailyFreeGames, 2);
      expect(fromJson.tokenCount, 10);
      expect(fromJson.glowDustCount, 50);
    });

    test('copyWith behaves correctly', () {
      const profile = UserProfile();
      final updated = profile.copyWith(tokenCount: 5, activeBallSkin: 'ball_gold');

      expect(updated.tokenCount, 5);
      expect(updated.activeBallSkin, 'ball_gold');
      expect(updated.dailyFreeGames, 3); // Unchanged default
    });
  });

  group('UserProfileService Tests', () {
    late UserProfileService service;
    late FakeFirebaseAuth fakeAuth;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = UserProfileService.instance;
      fakeAuth = FakeFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
      service.authInstance = fakeAuth;
      service.firestoreInstance = fakeFirestore;
    });

    test('Initializes with default profile when cache is empty', () async {
      // Mock user ID to bypass real Firebase connection in unit tests
      service.mockUserId = 'mock_uid_123';
      await service.initialize();

      expect(service.profile.dailyFreeGames, 3);
      expect(service.profile.tokenCount, 0);
      expect(service.profile.isInfiniteUnlocked, isFalse);
    });

    test('Deducts free plays and tokens sequentially', () async {
      service.mockUserId = 'mock_uid_123';
      await service.initialize();

      // Set initial values
      final profile = const UserProfile(dailyFreeGames: 1, tokenCount: 2);
      await service.saveProfile(profile);

      // Spend first credit (uses free daily game)
      bool success = service.spendPlayCredit();
      expect(success, isTrue);
      expect(service.profile.dailyFreeGames, 0);
      expect(service.profile.tokenCount, 2);

      // Spend second credit (uses premium token)
      success = service.spendPlayCredit();
      expect(success, isTrue);
      expect(service.profile.dailyFreeGames, 0);
      expect(service.profile.tokenCount, 1);

      // Spend third credit (uses premium token)
      success = service.spendPlayCredit();
      expect(success, isTrue);
      expect(service.profile.dailyFreeGames, 0);
      expect(service.profile.tokenCount, 0);

      // Spend fourth credit (should fail)
      success = service.spendPlayCredit();
      expect(success, isFalse);
    });

    test('Infinite pass allows unlimited plays without deduction', () async {
      service.mockUserId = 'mock_uid_123';
      await service.initialize();

      const profile = UserProfile(dailyFreeGames: 0, tokenCount: 0, isInfiniteUnlocked: true);
      await service.saveProfile(profile);

      bool success = service.spendPlayCredit();
      expect(success, isTrue);
      expect(service.profile.dailyFreeGames, 0);
      expect(service.profile.tokenCount, 0);
    });

    test('Stale cached session (INVALID_REFRESH_TOKEN) is automatically signed out', () async {
      final invalidUser = FakeUser(uid: 'invalid_token_uid');
      fakeAuth.mockSetCurrentUser(invalidUser);

      expect(fakeAuth.currentUser, isNotNull);
      expect(fakeAuth.currentUser!.uid, 'invalid_token_uid');

      await service.initialize();

      expect(fakeAuth.currentUser, isNull);
      expect(service.userId, isNull);
    });

    test('Valid cached session is successfully preserved', () async {
      final validUser = FakeUser(uid: 'valid_uid_789');
      fakeAuth.mockSetCurrentUser(validUser);

      expect(fakeAuth.currentUser, isNotNull);
      expect(fakeAuth.currentUser!.uid, 'valid_uid_789');

      await service.initialize();

      expect(fakeAuth.currentUser, isNotNull);
      expect(service.userId, 'valid_uid_789');
    });
  });
}
