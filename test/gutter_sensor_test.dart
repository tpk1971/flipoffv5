import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:flipoff/game/flipoff_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gutter sensor should detect ball entry and request reset', (WidgetTester tester) async {
    final game = FlipoffGame();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(900, 1600)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();

    // Allow async assets to load and children components to mount
    for (int i = 0; i < 10; i++) {
      game.update(0.016);
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Reset ball position and velocity to initial spawn coordinates
    game.ball.body.setTransform(Vector2(4.5, 3.0), 0.0);
    game.ball.body.linearVelocity = Vector2.zero();
    game.ball.body.angularVelocity = 0.0;

    // Verify ball starts at its spawn point
    expect(game.ball.body.position.x, closeTo(4.5, 0.01));
    expect(game.ball.body.position.y, closeTo(3.0, 0.01));

    // Force the ball's position into the gutter sensor box (centered at 7.5, 15.9)
    game.ball.body.setTransform(Vector2(7.5, 15.9), 0.0);

    // Run 3 physics steps to let contact register, trigger reset, and start falling again
    for (int i = 0; i < 3; i++) {
      game.update(0.016);
    }

    // Since the contact occurred, the deferred reset should execute,
    // positioning the ball back to its spawn point and clearing velocities.
    expect(
      game.ball.body.position.x,
      closeTo(4.5, 0.05),
      reason: 'Ball X-position should reset to 4.5',
    );
    expect(
      game.ball.body.position.y,
      closeTo(3.0, 0.5),
      reason: 'Ball Y-position should reset to 3.0 (with gravity tolerance)',
    );
    expect(
      game.ball.body.linearVelocity.x,
      closeTo(0.0, 0.05),
      reason: 'Ball linear velocity X should be close to zero',
    );
    expect(
      game.ball.body.linearVelocity.y,
      closeTo(0.0, 0.5),
      reason: 'Ball linear velocity Y should be close to zero (with gravity tolerance)',
    );
    expect(
      game.ball.body.angularVelocity,
      closeTo(0.0, 0.05),
      reason: 'Ball angular velocity should be zeroed',
    );
  });
}
