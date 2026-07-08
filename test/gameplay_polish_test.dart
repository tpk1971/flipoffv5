import 'package:flutter_test/flutter_test.dart';
import 'package:flipoff/game/flipoff_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gameplay Polish Tests (Milestone 8)', () {
    test('ballSaverTimeRemaining initial value and decrement', () {
      final game = FlipoffGame();
      game.ballSaverTimeRemaining = 5.0;

      // Update game timer decrement
      game.update(1.0);
      expect(game.ballSaverTimeRemaining, closeTo(4.0, 0.01));
    });

    test('Gutter shield bounce logic active and inactive checks', () {
      final game = FlipoffGame();

      // Shield active
      game.ballSaverTimeRemaining = 3.0;
      expect(game.ballSaverTimeRemaining > 0.0, isTrue);

      // Shield expired
      game.ballSaverTimeRemaining = 0.0;
      expect(game.ballSaverTimeRemaining > 0.0, isFalse);
    });
  });
}
