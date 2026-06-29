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

  /// Active portal vortex paint.
  late final Paint _activePaint;

  /// Inactive/locked portal paint.
  late final Paint _inactivePaint;

  /// Glowing neon border paint.
  late final Paint _borderPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _activePaint = Paint()
      ..color = const Color(0x997B2CBF) // Glowing semi-transparent violet
      ..style = PaintingStyle.fill;

    _inactivePaint = Paint()
      ..color = const Color(0x33FFFFFF) // Faint translucent white/grey
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = const Color(0xFF9D4EDD) // Vibrant violet outline
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
      ..isSensor = true; // Use sensor so the ball passes through it seamlessly

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_unlocked) {
      canvas.drawCircle(Offset.zero, radius, _activePaint);
      canvas.drawCircle(Offset.zero, radius, _borderPaint);
    } else {
      canvas.drawCircle(Offset.zero, radius, _inactivePaint);
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (_unlocked && other is Ball) {
      game.roomManager.onPortalEntered();
    }
  }
}
