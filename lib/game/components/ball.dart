import 'dart:ui';
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

  /// The paint used to draw the chrome marble shader effect.
  late final Paint _chromePaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set up a radial gradient to render a high-performance 3D chrome sphere
    // that reflects the surrounding neon teal highlights and dark obsidian backdrop.
    _chromePaint = Paint()
      ..shader = Gradient.radial(
        Offset.zero,
        0.25,
        const [
          Color(0xFFFFFFFF), // Specular reflection point
          Color(0xFFE2EAFC), // Chrome light body
          Color(0xFF00F5D4), // Teal highlight reflection
          Color(0xFF240046), // Deep violet shadow
          Color(0xFF0D0E15), // Shadow edge
        ],
        const [0.0, 0.15, 0.5, 0.85, 1.0],
        TileMode.clamp,
        null,
        const Offset(-0.08, -0.08), // Shifting the specular highlight to the top-left focal point
      );
  }

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
      ..restitution = 0.5; // Slightly bouncy, but controllable on the flipper

    return world.createBody(def)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    // Draw the chrome marble circle, overriding default wireframe rendering
    canvas.drawCircle(Offset.zero, 0.25, _chromePaint);
  }
}
