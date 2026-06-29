import 'package:flame_forge2d/flame_forge2d.dart';

/// The pinball component representing the ball in play.
///
/// This component creates a dynamic circular physical body in the Forge2D world,
/// with predefined density, friction, and restitution (bounciness).
class Ball extends BodyComponent {
  /// Creates a ball component at the specified initial [initialPosition].
  Ball({required this.initialPosition});

  /// The initial position of the ball in the physical world.
  final Vector2 initialPosition;

  @override
  Body createBody() {
    final def = BodyDef()
      ..userData = this
      ..type = BodyType.dynamic
      ..position = initialPosition
      ..bullet = true; // Use bullet physics to prevent tunneling through boundaries

    final shape = CircleShape()..radius = 0.25;

    final fixtureDef = FixtureDef(shape)
      ..density = 1.0
      ..friction = 0.4
      ..restitution = 0.4; // Slightly bouncy, but controllable on the flipper

    return world.createBody(def)..createFixture(fixtureDef);
  }
}
