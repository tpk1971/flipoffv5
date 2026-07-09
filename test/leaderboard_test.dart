import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flipoff/game/models/user_profile.dart';
import 'package:flipoff/game/services/user_profile_service.dart';
import 'package:flipoff/game/leaderboard_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Leaderboard & High Score Tests (Milestone 11)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final service = UserProfileService.instance;
      await service.initialize();
    });

    test('UserProfile highScores constructor and JSON mapping', () {
      const profile = UserProfile(highScores: [1000, 500]);
      expect(profile.highScores, containsAll([1000, 500]));

      final json = profile.toJson();
      expect(json['highScores'], containsAll([1000, 500]));

      final parsed = UserProfile.fromJson(json);
      expect(parsed.highScores, containsAll([1000, 500]));
    });

    test('UserProfile copyWith maintains highScores list', () {
      const profile = UserProfile(highScores: [1000]);
      final updated = profile.copyWith(highScores: [1000, 800]);
      expect(updated.highScores, containsAll([1000, 800]));
    });

    test('UserProfileService records, sorts, and caps top 10 scores', () async {
      final service = UserProfileService.instance;
      
      // Submit multiple scores out of order
      await service.recordScore(500);
      await service.recordScore(1200);
      await service.recordScore(300);
      await service.recordScore(900);
      
      expect(service.profile.highScores.first, equals(1200)); // Highest first
      expect(service.profile.highScores.length, equals(4));

      // Submit 8 more scores to overflow top 10 limit (total 12 scores)
      for (int i = 1; i <= 8; i++) {
        await service.recordScore(i * 100);
      }
      
      expect(service.profile.highScores.length, equals(10)); // Capped at 10
      expect(service.profile.highScores.contains(300), isTrue);
    });

    testWidgets('LeaderboardOverlay renders tabs and close action', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardOverlay(),
          ),
        ),
      );

      // Verify title renders
      expect(find.text('LEADERBOARDS'), findsOneWidget);
      expect(find.text('PERSONAL'), findsOneWidget);
      expect(find.text('DAILY'), findsOneWidget);
      expect(find.text('GLOBAL'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);
    });
  });
}
