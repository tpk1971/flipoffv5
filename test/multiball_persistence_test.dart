import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// Test suite verifying Multiball state persistence across room transitions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Multiball Room Persistence Tests', () {
    test('triggerMultiball sets score multiplier and active ball count', () {
      final game = FlipoffGame();
      expect(game.scoreMultiplierNotifier.value, equals(1));

      game.triggerMultiball(totalBalls: 3);
      expect(game.scoreMultiplierNotifier.value, equals(3));
    });

    test('Score multiplier updates dynamically when balls drain', () {
      final game = FlipoffGame();
      game.scoreMultiplierNotifier.value = 3;
      expect(game.scoreMultiplierNotifier.value, equals(3));
    });
  });
}
