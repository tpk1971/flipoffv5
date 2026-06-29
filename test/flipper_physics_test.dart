import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flipoff/game/flipoff_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flipper joint angles should stay strictly within limits', (WidgetTester tester) async {
    final game = FlipoffGame();

    // Trigger async load and lifecycle initialization
    await game.onLoad();
    game.onGameResize(Vector2(900, 1600));
    game.onMount();

    // Verify flipper was successfully loaded and added
    expect(game.roomManager.activeLayout?.flipper, isNotNull);

    // Let the simulation settle for a few frames (approx 0.5s of game time)
    for (int i = 0; i < 30; i++) {
      game.update(0.016);
    }

    // At rest, motor pulls the flipper down to the upper limit of 15 degrees (0.2618 rad)
    expect(
      game.roomManager.activeLayout!.flipper.jointAngle,
      closeTo(15 * math.pi / 180, 0.05),
      reason: 'Flipper should rest at 15 degrees',
    );

    // Trigger flipper sweep upward
    game.roomManager.activeLayout!.flipper.activate();

    // Run the physics simulation forward (approx 1s of game time) to allow complete sweep
    for (int i = 0; i < 60; i++) {
      game.update(0.016);
    }

    // At full sweep, the flipper should clamp at the lower limit of -25 degrees (-0.4363 rad)
    expect(
      game.roomManager.activeLayout!.flipper.jointAngle,
      closeTo(-25 * math.pi / 180, 0.05),
      reason: 'Flipper should clamp at -25 degrees when active',
    );

    // Deactivate flipper to test recovery return
    game.roomManager.activeLayout!.flipper.deactivate();

    // Let the simulation run to return to resting state
    for (int i = 0; i < 60; i++) {
      game.update(0.016);
    }

    // Flipper should return to the resting upper limit
    expect(
      game.roomManager.activeLayout!.flipper.jointAngle,
      closeTo(15 * math.pi / 180, 0.05),
      reason: 'Flipper should return to 15 degrees when released',
    );
  });
}
