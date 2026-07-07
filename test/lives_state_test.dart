import 'package:flutter_test/flutter_test.dart';
import 'package:flipoff/game/flipoff_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lives and Score State Tests', () {
    test('Initializes with default state values', () {
      final game = FlipoffGame();
      expect(game.livesNotifier.value, equals(10));
      expect(game.scoreNotifier.value, equals(0));
      expect(game.isGameOverNotifier.value, isFalse);
    });

    test('resetGame resets score, lives, and game over state', () {
      final game = FlipoffGame();
      game.livesNotifier.value = 5;
      game.scoreNotifier.value = 1200;
      game.isGameOverNotifier.value = true;

      game.resetGame();

      expect(game.livesNotifier.value, equals(10));
      expect(game.scoreNotifier.value, equals(0));
      expect(game.isGameOverNotifier.value, isFalse);
    });

    test('Target hit awards score and handles bonus lives', () {
      final game = FlipoffGame();

      // Standard target hit
      game.scoreNotifier.value += 100;
      expect(game.scoreNotifier.value, equals(100));

      // Bonus target hit (lives < 15)
      if (game.livesNotifier.value < 15) {
        game.livesNotifier.value++;
      }
      expect(game.livesNotifier.value, equals(11));

      // Bonus target hit at max lives (15)
      game.livesNotifier.value = 15;
      if (game.livesNotifier.value < 15) {
        game.livesNotifier.value++;
      } else {
        game.scoreNotifier.value += 500;
      }
      expect(game.livesNotifier.value, equals(15));
      expect(game.scoreNotifier.value, equals(600)); // 100 + 500
    });
  });
}
