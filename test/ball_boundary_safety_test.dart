import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// Test suite verifying active ball safety checks and out-of-bounds reset triggers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Active Ball Safety Verification Tests', () {
    test('FlipoffGame initializes with default 3 lives and active game state', () {
      final game = FlipoffGame();
      expect(game.livesNotifier.value, equals(3));
      expect(game.isGameOverNotifier.value, isFalse);
    });

    test('Requesting ball reset deducts 1 life when lives > 0', () {
      final game = FlipoffGame();
      game.livesNotifier.value = 3;

      game.requestBallReset();
      // Execute game update cycle
      game.update(0.016);

      expect(game.livesNotifier.value, equals(2));
    });
  });
}
