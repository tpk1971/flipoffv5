import 'dart:math' as math;
import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flipoff/game/audio_controller.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// An asymmetrical single flipper pivoted on the left.
///
/// This component creates a dynamic, tapered flipper body and anchors it to
/// a static body in the world via a [RevoluteJoint] with motor controls and angle limits.
class DoubleWideFlipper extends BodyComponent<FlipoffGame> {
  /// Creates a flipper component at the specified pivot [initialPosition].
  ///
  /// [length] determines how far the flipper extends to the right.
  DoubleWideFlipper({
    required this.initialPosition,
    this.length = 5.5,
    this.leftRadius = 0.3,
    this.rightRadius = 0.15,
  });

  /// The position of the pivot anchor in the physical world.
  final Vector2 initialPosition;

  /// The length of the flipper.
  final double length;

  /// The thickness radius at the pivot (left) end.
  final double leftRadius;

  /// The thickness radius at the tip (right) end.
  final double rightRadius;

  /// The revolute joint connecting this flipper to its static pivot anchor.
  RevoluteJoint? _joint;

  /// The paint used for the translucent glassmorphic flipper body.
  late final Paint _fillPaint;

  /// The paint used for the glowing sharp neon purple outline.
  late final Paint _borderPaint;

  /// The paint used for the outer neon glow stroke.
  late final Paint _glowPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Glassmorphic fill (low opacity white)
    _fillPaint = Paint()
      ..color = const Color(0x14FFFFFF) // ~8% opacity white
      ..style = PaintingStyle.fill;

    // Glowing border paint (neon purple)
    _borderPaint = Paint()
      ..color = const Color(0xFF9D4EDD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.06;

    // Soft outer neon glow
    _glowPaint = Paint()
      ..color = const Color(0x4D9D4EDD) // Translucent neon purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.16
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.05);
  }

  @override
  Body createBody() {
    // The flipper body starts at the pivot position
    final def = BodyDef()
      ..type = BodyType.dynamic
      ..position = initialPosition;

    final body = world.createBody(def);

    // Convex polygon representing the tapered flipper shape.
    // The vertices must be defined in counter-clockwise order.
    final shape = PolygonShape()
      ..set([
        Vector2(0, -leftRadius),
        Vector2(length, -rightRadius),
        Vector2(length, rightRadius),
        Vector2(0, leftRadius),
      ]);

    final fixtureDef = FixtureDef(shape)
      ..density = 1.5
      ..friction = 0.4
      ..restitution = 0.4; // Flipper rubber restitution

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void onMount() {
    super.onMount();

    // Create a static anchor body at the pivot position
    final anchorDef = BodyDef()
      ..type = BodyType.static
      ..position = initialPosition;
    final anchorBody = world.createBody(anchorDef);

    // Define and create the revolute joint
    final jointDef = RevoluteJointDef()
      ..initialize(anchorBody, body, initialPosition)
      ..lowerAngle = -25 * math.pi / 180
      ..upperAngle = 15 * math.pi / 180
      ..enableLimit = true
      ..maxMotorTorque = 1800.0
      ..motorSpeed = 30.0 // Pulls the flipper down to the resting upper limit
      ..enableMotor = true;

    final joint = RevoluteJoint(jointDef);
    world.createJoint(joint);
    _joint = joint;
  }

  /// Sets the motor speed to swing the flipper upwards.
  void activate() {
    _joint?.motorSpeed = -45.0; // Fast upward sweep to lower limit (-25 deg)
    HapticFeedback.selectionClick();
    GameAudioController.instance.playSfx('sfx_flipper.wav');
  }

  /// Sets the motor speed to return the flipper to its resting position.
  void deactivate() {
    _joint?.motorSpeed = 30.0; // Fast downward return to upper limit (15 deg)
    HapticFeedback.selectionClick();
  }

  /// Returns the current joint angle in radians.
  double get jointAngle => _joint?.jointAngle() ?? 0.0;

  @override
  void render(Canvas canvas) {
    // Get the dynamic theme color
    final themeColor = game.activeTheme.flipperColor;
    _borderPaint.color = themeColor;
    _glowPaint.color = themeColor.withValues(alpha: 0.3);

    // Construct the path representing the tapered flipper body
    final path = Path()
      ..moveTo(0, -leftRadius)
      ..lineTo(length, -rightRadius)
      ..lineTo(length, rightRadius)
      ..lineTo(0, leftRadius)
      ..close();

    // Render outer neon glow stroke first
    canvas.drawPath(path, _glowPaint);
    // Render glassmorphic fill
    canvas.drawPath(path, _fillPaint);
    // Render sharp neon border
    canvas.drawPath(path, _borderPaint);
  }
}
