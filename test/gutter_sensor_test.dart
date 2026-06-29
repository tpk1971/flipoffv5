import 'package:flutter_test/flutter_test.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flipoff/game/flipoff_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gutter sensor should detect ball entry and request reset', (WidgetTester tester) async {
    final game = FlipoffGame();

    // Trigger async load and lifecycle initialization
    await game.onLoad();
    game.onGameResize(Vector2(900, 1600));
    game.onMount();

    // Verify ball starts at its spawn point
    expect(game.ball.body.position.x, closeTo(4.5, 0.01));
    expect(game.ball.body.position.y, closeTo(3.0, 0.01));

    // Force the ball's position into the gutter sensor box (centered at 7.5, 15.9)
    game.ball.body.setTransform(Vector2(7.5, 15.9), 0.0);

    // Run physics simulation steps to allow collision contact to register and resolve
    for (int i = 0; i < 5; i++) {
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
      closeTo(3.0, 0.05),
      reason: 'Ball Y-position should reset to 3.0',
    );
    expect(
      game.ball.body.linearVelocity,
      equals(Vector2.zero()),
      reason: 'Ball linear velocity should be zeroed',
    );
    expect(
      game.ball.body.angularVelocity,
      equals(0.0),
      reason: 'Ball angular velocity should be zeroed',
    );
  });
}
