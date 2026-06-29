import 'package:flutter_test/flutter_test.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flipoff/game/flipoff_game.dart';
import 'package:flipoff/game/components/bumper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ball Spin Physics and Deflection Tests', () {
    late FlipoffGame game;

    setUp(() async {
      game = FlipoffGame();
      await game.onLoad();
      game.onGameResize(Vector2(900, 1600));
      game.onMount();
    });

    testWidgets('Zero-Spin Control: ball drops vertically and bounces straight up', (WidgetTester tester) async {
      // 1. Create a flat horizontal static floor at y = 10.0
      final floorDef = BodyDef()..type = BodyType.static;
      final floorBody = game.world.createBody(floorDef);
      final edge = EdgeShape()..set(Vector2(0, 10.0), Vector2(9.0, 10.0));
      floorBody.createFixture(FixtureDef(edge)..friction = 0.4..restitution = 0.5);

      // 2. Position the ball above the floor with zero spin and vertical velocity
      game.ball.body.setTransform(Vector2(4.5, 9.0), 0.0);
      game.ball.body.linearVelocity = Vector2(0.0, 5.0);
      game.ball.body.angularVelocity = 0.0;

      // 3. Step physics simulation loop to let the ball collide and bounce
      for (int i = 0; i < 40; i++) {
        game.update(0.016);
      }

      // 4. Verify the ball bounces straight up without horizontal deflection
      expect(game.ball.body.position.x, closeTo(4.5, 0.02));
      expect(game.ball.body.linearVelocity.x, closeTo(0.0, 0.02));
    });

    testWidgets('Spin Deflection: spinning ball drops vertically and bounces laterally', (WidgetTester tester) async {
      // 1. Create a flat horizontal static floor at y = 10.0
      final floorDef = BodyDef()..type = BodyType.static;
      final floorBody = game.world.createBody(floorDef);
      final edge = EdgeShape()..set(Vector2(0, 10.0), Vector2(9.0, 10.0));
      floorBody.createFixture(FixtureDef(edge)..friction = 0.4..restitution = 0.5);

      // 2. Position the ball above the floor with high clockwise spin and vertical velocity
      game.ball.body.setTransform(Vector2(4.5, 9.0), 0.0);
      game.ball.body.linearVelocity = Vector2(0.0, 5.0);
      game.ball.body.angularVelocity = 30.0; // 30 rad/s clockwise spin

      // 3. Step physics simulation loop to let the ball collide and bounce
      for (int i = 0; i < 40; i++) {
        game.update(0.016);
      }

      // 4. Verify that spin causes horizontal deflection (non-zero X position shift and X velocity)
      expect(game.ball.body.position.x, isNot(closeTo(4.5, 0.05)));
      expect(game.ball.body.linearVelocity.x.abs(), greaterThan(0.1));
      expect(game.ball.body.angularVelocity, isNot(closeTo(30.0, 0.05)));
    });

    testWidgets('Bumper Scatter: perfectly vertical collision triggers spin and breaks loop symmetry', (WidgetTester tester) async {
      // 1. Spawn a bumper at (4.5, 6.0) in the world
      final bumper = Bumper(initialPosition: Vector2(4.5, 6.0), radius: 0.6);
      await game.world.add(bumper);

      // Wait for bumper mounting to complete
      for (int i = 0; i < 5; i++) {
        game.update(0.016);
        await tester.pump(const Duration(milliseconds: 16));
      }

      // 2. Position the ball directly above the bumper (perfect alignment on x = 4.5)
      // and let it drop vertically onto the bumper
      game.ball.body.setTransform(Vector2(4.5, 3.0), 0.0);
      game.ball.body.linearVelocity = Vector2(0.0, 5.0);
      game.ball.body.angularVelocity = 0.0;

      // 3. Step physics loop until collision contact occurs and resolves
      for (int i = 0; i < 40; i++) {
        game.update(0.016);
        await tester.pump(const Duration(milliseconds: 16));
      }

      // 4. Verify that the bumper's contact callback successfully injected scatter velocity
      // and spin to break the vertical loop symmetry
      expect(game.ball.body.linearVelocity.x.abs(), greaterThan(0.05));
      expect(game.ball.body.angularVelocity.abs(), greaterThan(1.0));
    });
  });
}
