import 'dart:math' as math;
import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flipoff/game/components/ball.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// A static sensor component representing the exit portal.
///
/// Unlocks when all targets are destroyed. Ball contact with the
/// unlocked portal triggers the next level loading sequence.
class ExitPortal extends BodyComponent<FlipoffGame> with ContactCallbacks {
  /// The local position of the portal in the room's coordinate system.
  final Vector2 initialPosition;

  /// The radius of the portal collision sensor.
  final double radius;

  /// Creates an exit portal at [initialPosition] with [radius].
  ExitPortal({
    required this.initialPosition,
    required this.radius,
  });

  /// Whether the portal is currently unlocked and receptive to ball entries.
  bool _unlocked = false;

  /// Gets the current unlocked status of the portal.
  bool get unlocked => _unlocked;

  /// Unlocks the portal, changing its visual styling to active neon.
  void unlock() {
    _unlocked = true;
  }

  /// Reset the portal to locked state (e.g. for reinitialization).
  void lock() {
    _unlocked = false;
  }

  /// Glowing neon border paint.
  late final Paint _borderPaint;

  /// The current rotation angle for the swirling animation.
  double _rotationAngle = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _borderPaint = Paint()
      ..color = const Color(0xFF9D4EDD) // Vibrant violet outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.06;
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
      ..isSensor = true; // Use sensor so the ball passes through it seamlessly

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_unlocked) {
      // Swirl rotation speed: ~3.0 rad/s
      _rotationAngle += 3.0 * dt;
      if (_rotationAngle > 2 * math.pi) {
        _rotationAngle -= 2 * math.pi;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_unlocked) {
      // 1. Draw soft outer blur glow
      final glowPaint = Paint()
        ..color = const Color(0x339D4EDD) // Translucent neon purple
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.08);
      canvas.drawCircle(Offset.zero, radius * 1.25, glowPaint);

      // 2. Draw base swirling radial gradient
      final radialGradientPaint = Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          radius,
          const [
            Color(0xFFE0AAFF), // Vibrant violet center
            Color(0x997B2CBF), // Translucent violet mid-ground
            Color(0x007B2CBF), // Transparent outer edge
          ],
          const [0.0, 0.6, 1.0],
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, radius, radialGradientPaint);

      // 3. Draw outer swirl arms rotating clockwise
      canvas.save();
      canvas.rotate(_rotationAngle);
      final armPaint = Paint()
        ..color = const Color(0xFFC77DFF) // Lighter neon violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05;
      for (int i = 0; i < 4; i++) {
        final double angle = i * math.pi / 2;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          angle,
          math.pi / 3,
          false,
          armPaint,
        );
      }
      canvas.restore();

      // 4. Draw inner swirl arms rotating counter-clockwise
      canvas.save();
      canvas.rotate(-_rotationAngle * 1.6);
      final innerArmPaint = Paint()
        ..color = const Color(0xFFE0AAFF) // Soft bright highlight violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.03;
      for (int i = 0; i < 3; i++) {
        final double angle = i * 2 * math.pi / 3;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: radius * 0.7),
          angle,
          math.pi / 4,
          false,
          innerArmPaint,
        );
      }
      canvas.restore();

      // 5. Draw the active neon boundary border
      canvas.drawCircle(Offset.zero, radius, _borderPaint);
    } else {
      // Render locked state as a faint translucent dotted/dashed circle
      final double dashLength = 0.15;
      final double spaceLength = 0.15;
      final double circumference = 2 * math.pi * radius;
      final int dashCount = (circumference / (dashLength + spaceLength)).floor();

      final Paint dashPaint = Paint()
        ..color = const Color(0x33FFFFFF) // Faint translucent white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.04;

      for (int i = 0; i < dashCount; i++) {
        final double startAngle = (i * 2 * math.pi) / dashCount;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          startAngle,
          dashLength / radius,
          false,
          dashPaint,
        );
      }
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (_unlocked && other is Ball) {
      game.roomManager.onPortalEntered(other);
    }
  }
}
