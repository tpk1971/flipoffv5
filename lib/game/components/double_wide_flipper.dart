import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart';

/// An asymmetrical single flipper pivoted on the left.
///
/// This component creates a dynamic, tapered flipper body and anchors it to
/// a static body in the world via a [RevoluteJoint] with motor controls and angle limits.
class DoubleWideFlipper extends BodyComponent {
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
      ..maxMotorTorque = 400.0
      ..motorSpeed = 15.0 // Pulls the flipper down to the resting upper limit
      ..enableMotor = true;

    final joint = RevoluteJoint(jointDef);
    world.createJoint(joint);
    _joint = joint;
  }

  /// Sets the motor speed to swing the flipper upwards.
  void activate() {
    _joint?.motorSpeed = -25.0; // Fast upward sweep to lower limit (-25 deg)
  }

  /// Sets the motor speed to return the flipper to its resting position.
  void deactivate() {
    _joint?.motorSpeed = 15.0; // Fast downward return to upper limit (15 deg)
  }

  /// Returns the current joint angle in radians.
  double get jointAngle => _joint?.jointAngle() ?? 0.0;
}
