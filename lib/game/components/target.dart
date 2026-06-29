import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flipoff/game/components/ball.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// A static crystal target component that the ball collides with.
///
/// Hitting this target deactivates/destroys it, registers scoring,
/// and updates the active level objective.
class Target extends BodyComponent<FlipoffGame> with ContactCallbacks {
  /// The local position of this target in the room's coordinate system.
  final Vector2 initialPosition;

  /// Creates a target component at the specified [initialPosition].
  Target({required this.initialPosition});

  /// The glassmorphic/neon fill paint for the target.
  late final Paint _paint;

  /// The glow outline paint for the target.
  late final Paint _borderPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _paint = Paint()
      ..color = const Color(0xAA00E8C6) // Neon Teal with glass transparency
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = const Color(0xFF00E8C6) // Full glowing neon teal border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05;
  }

  @override
  Body createBody() {
    final def = BodyDef()
      ..userData = this
      ..type = BodyType.static
      ..position = initialPosition;

    final body = world.createBody(def);
    final shape = CircleShape()..radius = 0.3;

    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.4
      ..friction = 0.1;

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw the core circle
    canvas.drawCircle(Offset.zero, 0.3, _paint);
    // Draw the neon glow border outline
    canvas.drawCircle(Offset.zero, 0.3, _borderPaint);
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball) {
      // Safe deferred removal from the Flame component tree
      removeFromParent();
      // Notify the active room manager
      game.roomManager.onTargetHit();
    }
  }
}
