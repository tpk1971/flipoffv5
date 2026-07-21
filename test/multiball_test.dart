import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:flipoff/game/flipoff_game.dart';
import 'package:flipoff/game/components/target.dart';
import 'fakes.dart';

/// Test suite verifying the Multiball Mode features: ball spawning,
/// score multipliers, and multi-ball drain protection.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multiball Mode Tests', () {
    testWidgets('triggerMultiball spawns 3 balls and sets 3x score multiplier', (WidgetTester tester) async {
      final game = FlipoffGame();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 1600)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(
              game: game,
              overlayBuilderMap: {
                'gameOver': (context, game) => const SizedBox(),
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await game.ready();

      // Initial single ball state
      expect(game.activeBalls.length, equals(1));
      expect(game.scoreMultiplierNotifier.value, equals(1));

      // Trigger multiball
      game.triggerMultiball(totalBalls: 3);

      // Verify active ball count and multiplier update
      expect(game.activeBalls.length, equals(3));
      expect(game.scoreMultiplierNotifier.value, equals(3));
    });

    testWidgets('Hitting a MultiballTarget awards multiplied points and activates Multiball', (WidgetTester tester) async {
      final game = FlipoffGame();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 1600)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(
              game: game,
              overlayBuilderMap: {
                'gameOver': (context, game) => const SizedBox(),
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await game.ready();

      final target = Target(
        initialPosition: Vector2(4.5, 3.0),
        isMultiballTarget: true,
      );
      await game.world.add(target);
      await tester.pump();

      // Initial score is 0, multiplier is 1x
      expect(game.scoreNotifier.value, equals(0));

      // Simulate contact hit with ball
      target.beginContact(game.ball, FakeContact());

      // Base multiball target score is 250 * 1 = 250
      expect(game.scoreNotifier.value, equals(250));
      expect(game.activeBalls.length, equals(3));
      expect(game.scoreMultiplierNotifier.value, equals(3));
    });

    testWidgets('Draining secondary balls removes them without reducing livesNotifier', (WidgetTester tester) async {
      final game = FlipoffGame();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 1600)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GameWidget(
              game: game,
              overlayBuilderMap: {
                'gameOver': (context, game) => const SizedBox(),
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await game.ready();

      // Disable ball saver shield
      game.ballSaverTimeRemaining = 0.0;
      game.livesNotifier.value = 3;

      // Trigger multiball (3 balls total)
      game.triggerMultiball(totalBalls: 3);
      expect(game.activeBalls.length, equals(3));

      final balls = game.activeBalls;
      final secondBall = balls[1];

      // Force second ball far out of bounds (drain)
      secondBall.body.setTransform(Vector2(20.0, 3.0), 0.0);

      // Run update loop to trigger out-of-bounds check
      game.update(0.016);

      // Lives should still be 3, but second ball removed and multiplier reduced to 2
      expect(game.livesNotifier.value, equals(3));
      expect(game.scoreMultiplierNotifier.value, equals(2));
    });
  });
}
