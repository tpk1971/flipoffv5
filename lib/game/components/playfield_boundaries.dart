import 'dart:ui';
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

  /// Paint used for outer boundaries.
  late final Paint _wallPaint;

  /// Outer neon glow boundary paint.
  late final Paint _wallGlowPaint;

  /// Paint used for the gutter/drain danger areas.
  late final Paint _gutterPaint;

  /// Outer neon glow gutter paint.
  late final Paint _gutterGlowPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Active Neon Purple for walls
    _wallPaint = Paint()
      ..color = const Color(0xFF9D4EDD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.08;

    _wallGlowPaint = Paint()
      ..color = const Color(0x4D9D4EDD) // Translucent purple glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.05);

    // Warning Red for drain gutter sloped floors
    _gutterPaint = Paint()
      ..color = const Color(0xFFF25C54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.08;

    _gutterGlowPaint = Paint()
      ..color = const Color(0x4DF25C54) // Translucent red glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.05);
  }

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

  @override
  void render(Canvas canvas) {
    const width = 9.0;
    const height = 16.0;

    // Top wall line
    _drawGlowingLine(canvas, Offset(0, yOffset), Offset(width, yOffset), _wallPaint, _wallGlowPaint);
    // Left wall line
    _drawGlowingLine(canvas, Offset(0, yOffset), Offset(0, height + yOffset), _wallPaint, _wallGlowPaint);
    // Right wall line
    _drawGlowingLine(canvas, Offset(width, yOffset), Offset(width, height + yOffset), _wallPaint, _wallGlowPaint);

    // Gutter/drain sloped floors funnelling to bottom right opening
    _drawGlowingLine(canvas, Offset(0, 15.2 + yOffset), Offset(6.8, 16.0 + yOffset), _gutterPaint, _gutterGlowPaint);
    _drawGlowingLine(canvas, Offset(9.0, 15.2 + yOffset), Offset(8.2, 16.0 + yOffset), _gutterPaint, _gutterGlowPaint);
  }

  void _drawGlowingLine(Canvas canvas, Offset p1, Offset p2, Paint paint, Paint glowPaint) {
    canvas.drawLine(p1, p2, glowPaint);
    canvas.drawLine(p1, p2, paint);
  }
}
