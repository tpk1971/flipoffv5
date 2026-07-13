import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// Test suite verifying the ball out-of-bounds escape detection logic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ball out-of-bounds escape should trigger lives deduction and reset', (WidgetTester tester) async {
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

    // Wait for the Flame game engine to be fully loaded and components mounted
    await game.ready();

    // Allow components to mount and run initial ticks
    for (int i = 0; i < 10; i++) {
      game.update(0.016);
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Set initial lives to 3 and score to 0
    game.livesNotifier.value = 3;
    game.scoreNotifier.value = 0;

    // Verify ball starts at its spawn point
    expect(game.ball.body.position.x, closeTo(4.5, 0.01));
    expect(game.ball.body.position.y, closeTo(3.0, 0.01));
    expect(game.livesNotifier.value, equals(3));

    // Force ball saver shield to be inactive
    game.ballSaverTimeRemaining = 0.0;

    // Force the ball's position far out of bounds (escaped)
    // E.g., x = 20.0 (playfield width is 9.0)
    game.ball.body.setTransform(Vector2(20.0, 3.0), 0.0);

    // Run update loop to trigger detection and deferred reset
    game.update(0.016); // Detect out of bounds
    game.update(0.016); // Process reset on the next frame

    // Verify lives deducted by 1 and ball reset to spawn pos
    expect(game.livesNotifier.value, equals(2));
    expect(game.ball.body.position.x, closeTo(4.5, 0.05));
    expect(game.ball.body.position.y, closeTo(3.0, 0.5));
    expect(game.isGameOverNotifier.value, isFalse);
  });

  testWidgets('Ball out-of-bounds escape when lives are 1 should trigger game over', (WidgetTester tester) async {
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

    // Wait for the Flame game engine to be fully loaded and components mounted
    await game.ready();

    // Allow components to mount and run initial ticks
    for (int i = 0; i < 10; i++) {
      game.update(0.016);
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Set initial lives to 1
    game.livesNotifier.value = 1;
    game.scoreNotifier.value = 100;

    // Force ball saver shield to be inactive
    game.ballSaverTimeRemaining = 0.0;

    // Force the ball's position far out of bounds (escaped)
    game.ball.body.setTransform(Vector2(-10.0, 3.0), 0.0);

    // Run update loop to trigger detection and deferred reset
    game.update(0.016); // Detect out of bounds
    game.update(0.016); // Process reset on the next frame

    // Verify lives deducted to 0, game over triggered, and ball parked off-screen
    expect(game.livesNotifier.value, equals(0));
    expect(game.isGameOverNotifier.value, isTrue);
    expect(game.ball.body.position.x, equals(-100.0));
    expect(game.ball.body.position.y, equals(-100.0));
  });
}
