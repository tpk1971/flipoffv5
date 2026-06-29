import 'dart:math' as math;
import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flipoff/game/components/ball.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// A static glassmorphic circular bumper component.
///
/// Configured with high restitution to bounce the ball with extra force.
class Bumper extends BodyComponent<FlipoffGame> with ContactCallbacks {
  /// The local position of this bumper in the room's coordinate system.
  final Vector2 initialPosition;

  /// The radius of the bumper.
  final double radius;

  /// Creates a bumper component at [initialPosition] with [radius].
  Bumper({
    required this.initialPosition,
    required this.radius,
  });

  /// The glassmorphic fill paint for the bumper.
  late final Paint _paint;

  /// The glowing neon border paint.
  late final Paint _borderPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _paint = Paint()
      ..color = const Color(0x889B5DE5) // Translucent Neon Violet
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = const Color(0xFFFF2E93) // Neon Pink border
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
    final shape = CircleShape()..radius = radius;

    final fixtureDef = FixtureDef(shape)
      ..restitution = 1.6 // Boost bounce impulse
      ..friction = 0.4;

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball) {
      final bumperPos = body.position;
      final ballPos = other.body.position;
      final normal = (ballPos - bumperPos).normalized();

      // Check if the collision is almost perfectly vertical (loop breaker)
      if (normal.x.abs() < 0.05) {
        final random = math.Random();
        final double direction = random.nextBool() ? 1.0 : -1.0;
        final double scatterForceX = direction * (0.2 + random.nextDouble() * 0.3); // 0.2 to 0.5 m/s
        other.body.linearVelocity = other.body.linearVelocity + Vector2(scatterForceX, 0);
      }

      // Inject a random angular velocity (spin) to simulate rubber grip spin transfer
      final random = math.Random();
      final double spinDir = random.nextBool() ? 1.0 : -1.0;
      final double randomSpin = spinDir * (5.0 + random.nextDouble() * 5.0); // 5 to 10 rad/s
      other.body.angularVelocity = randomSpin;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw the core bumper fill
    canvas.drawCircle(Offset.zero, radius, _paint);
    // Draw the active glowing border
    canvas.drawCircle(Offset.zero, radius, _borderPaint);
  }
}
