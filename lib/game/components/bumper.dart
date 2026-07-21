import 'dart:math' as math;
import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flipoff/game/components/ball.dart';
import 'package:flipoff/game/components/score_popup.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// A static glassmorphic circular bumper component.
///
/// Configured with high restitution to bounce the ball with extra force.
class Bumper extends BodyComponent<FlipoffGame> with ContactCallbacks {
  /// The local position of this bumper in the room's coordinate system.
  final Vector2 initialPosition;

  /// The physical radius of this circular bumper.
  final double radius;

  /// Creates a Bumper at the specified [initialPosition] and [radius].
  Bumper({
    required this.initialPosition,
    this.radius = 0.5,
  });

  /// The active scaling factor for the hit-response pulse animation.
  double _pulseScale = 1.0;

  /// The active glow highlight intensity for the hit-response pulse animation.
  double _pulseGlow = 0.0;

  /// Glassmorphic center fill paint.
  late final Paint _paint;

  /// Outer neon border paint.
  late final Paint _borderPaint;

  /// Cached paint for rendering collision pulses.
  late final Paint _glowPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _paint = Paint()
      ..color = const Color(0x99FF007F) // Glassmorphic Pink fill
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = const Color(0xFFFF007F) // Vibrant Neon Pink border outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05;

    _glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.05);
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
  void update(double dt) {
    super.update(dt);
    // Smoothly decay pulse scaling back to default (1.0)
    if (_pulseScale > 1.0) {
      _pulseScale -= 4.0 * dt;
      if (_pulseScale < 1.0) _pulseScale = 1.0;
    }
    // Smoothly decay the glow intensity back to zero
    if (_pulseGlow > 0.0) {
      _pulseGlow -= 4.0 * dt;
      if (_pulseGlow < 0.0) _pulseGlow = 0.0;
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball) {
      // Trigger visual scaling pulse and glow highlight
      _pulseScale = 1.25;
      _pulseGlow = 1.0;

      // Award score with active multiplier
      final points = 50 * game.scoreMultiplierNotifier.value;
      game.scoreNotifier.value += points;
      game.world.add(ScorePopup(text: '+$points', position: body.position.clone()));

      // Haptic bump collision feedback
      HapticFeedback.lightImpact();
      game.queueSfx('sfx_bumper.wav');

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
    // Get the dynamic theme color
    final themeColor = game.activeTheme.bumperColor;
    _borderPaint.color = themeColor;
    _paint.color = themeColor.withValues(alpha: 0.15);

    canvas.save();
    // Scale drawings around center pivot (Offset.zero)
    canvas.scale(_pulseScale);

    // Draw the core bumper fill
    canvas.drawCircle(Offset.zero, radius, _paint);

    // Render additional neon glow shadow if recently struck
    if (_pulseGlow > 0.0) {
      _glowPaint.color = themeColor.withValues(alpha: 0.4);
      _glowPaint.strokeWidth = 0.15 * _pulseGlow;
      canvas.drawCircle(Offset.zero, radius, _glowPaint);
    }

    // Draw the active glowing border
    canvas.drawCircle(Offset.zero, radius, _borderPaint);
    canvas.restore();
  }
}
