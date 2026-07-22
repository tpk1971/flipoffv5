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

    testWidgets('Draining main ball during multiball preserves it and copies extra ball state', (WidgetTester tester) async {
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

      // Main ball is game.ball. Let's record an extra ball's position and velocity.
      final extraBall = game.activeBalls.firstWhere((b) => b != game.ball);
      final targetPos = Vector2(2.0, 5.0);
      final targetVel = Vector2(1.0, -1.0);
      extraBall.body.setTransform(targetPos, 0.0);
      extraBall.body.linearVelocity = targetVel;

      // Force main ball out of bounds (drain)
      game.ball.body.setTransform(Vector2(20.0, 3.0), 0.0);

      // Run update loop to trigger out-of-bounds check
      game.update(0.016);

      // Main ball should be preserved, its position and velocity swapped with the extra ball, and the extra ball removed
      expect(game.livesNotifier.value, equals(3));
      expect(game.scoreMultiplierNotifier.value, equals(2));
      expect(game.activeBalls.contains(game.ball), isTrue, reason: 'Main ball must be preserved');
      expect(game.ball.body.position.x, closeTo(targetPos.x, 0.01));
      expect(game.ball.body.position.y, closeTo(targetPos.y, 0.01));
      expect(game.ball.body.linearVelocity.x, closeTo(targetVel.x, 0.01));
      expect(game.ball.body.linearVelocity.y, closeTo(targetVel.y, 0.01));
    });

    testWidgets('Entering portal with extra ball teleport/preserves main ball and transitions', (WidgetTester tester) async {
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

      // Trigger multiball
      game.triggerMultiball(totalBalls: 2);
      expect(game.activeBalls.length, equals(2));

      final extraBall = game.activeBalls.firstWhere((b) => b != game.ball);
      final portalPos = Vector2(4.5, 1.5); // room_1 portal position

      // Simulate extra ball hitting the portal
      game.roomManager.onPortalEntered(extraBall);

      // Verify that main ball is immediately moved to portal and extra ball is removed
      expect(game.activeBalls.length, equals(1));
      expect(game.activeBalls.first, equals(game.ball));
      expect(game.ball.body.position.x, closeTo(portalPos.x, 0.01));
      expect(game.ball.body.position.y, closeTo(portalPos.y, 0.01));
      expect(game.ball.body.linearVelocity, equals(Vector2.zero()));
    });
  });
}
