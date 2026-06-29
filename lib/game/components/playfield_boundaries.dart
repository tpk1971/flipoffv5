import 'package:flame_forge2d/flame_forge2d.dart';

/// Static boundaries of the pinball playfield.
///
/// This component creates the left, right, and top walls of the 9x16 meters
/// playfield, along with a sloped gutter at the bottom right.
class PlayfieldBoundaries extends BodyComponent {
  /// The vertical offset of these boundaries.
  final double yOffset;

  /// Creates the static boundaries for the game playfield with optional [yOffset].
  PlayfieldBoundaries({this.yOffset = 0.0});

  @override
  Body createBody() {
    final def = BodyDef()
      ..type = BodyType.static
      ..position = Vector2.zero();

    final body = world.createBody(def);

    // Playfield size is 9 x 16 meters
    const width = 9.0;
    const height = 16.0;

    // Define the walls offset by yOffset
    // Top wall
    body.createFixture(
      FixtureDef(
        EdgeShape()..set(Vector2(0, yOffset), Vector2(width, yOffset)),
        restitution: 0.1,
        friction: 0.4,
      ),
    );

    // Left wall
    body.createFixture(
      FixtureDef(
        EdgeShape()..set(Vector2(0, yOffset), Vector2(0, height + yOffset)),
        restitution: 0.1,
        friction: 0.4,
      ),
    );

    // Right wall
    body.createFixture(
      FixtureDef(
        EdgeShape()..set(Vector2(width, yOffset), Vector2(width, height + yOffset)),
        restitution: 0.1,
        friction: 0.4,
      ),
    );

    // Sloped bottom floor (left side): funnels ball to the gutter at the bottom right.
    // Starts at y = 15.2 (elevated) on the left, slopes down to y = 16.0 (bottom) at x = 6.8.
    body.createFixture(
      FixtureDef(
        EdgeShape()..set(Vector2(0, 15.2 + yOffset), Vector2(6.8, 16.0 + yOffset)),
        restitution: 0.1,
        friction: 0.4,
      ),
    );

    // Sloped bottom floor (right side): funnels ball to the gutter from the far right.
    // Starts at y = 15.2 (elevated) on the right, slopes down to y = 16.0 (bottom) at x = 8.2.
    body.createFixture(
      FixtureDef(
        EdgeShape()..set(Vector2(9.0, 15.2 + yOffset), Vector2(8.2, 16.0 + yOffset)),
        restitution: 0.1,
        friction: 0.4,
      ),
    );

    return body;
  }
}
