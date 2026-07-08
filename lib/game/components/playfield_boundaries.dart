import 'dart:math' as math;
import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flipoff/game/flipoff_game.dart';
import 'package:flipoff/game/components/ball.dart';

/// Static boundaries of the pinball playfield.
///
/// This component creates the left, right, and top walls of the 9x16 meters
/// playfield, along with a sloped gutter at the bottom right.
class PlayfieldBoundaries extends BodyComponent<FlipoffGame> with ContactCallbacks {
  /// The vertical offset of these boundaries.
  final double yOffset;

  /// Creates the static boundaries for the game playfield with optional [yOffset].
  PlayfieldBoundaries({this.yOffset = 0.0});

  /// List of boundary fixtures.
  final List<Fixture> _fixtures = [];

  /// The left slope gutter fixture.
  late final Fixture _leftGutterFixture;

  /// The right slope gutter fixture.
  late final Fixture _rightGutterFixture;

  /// Paint used for outer boundaries.
  late final Paint _wallPaint;

  /// Outer neon glow paint.
  late final Paint _wallGlowPaint;

  /// Paint used for the gutter/drain danger areas.
  late final Paint _gutterPaint;

  /// Outer neon glow gutter paint.
  late final Paint _gutterGlowPaint;

  /// Pre-allocated mutable paint for gutter shield pulse.
  late final Paint _pulseGutterPaint;

  /// Pre-allocated mutable paint for gutter shield pulse glow.
  late final Paint _pulseGutterGlowPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _wallPaint = Paint()
      ..color = const Color(0xFF9D4EDD) // Neon Purple wall outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05;

    _wallGlowPaint = Paint()
      ..color = const Color(0x339D4EDD) // Translucent glow backdrop
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.15;

    // Warning Red for drain gutter sloped floors
    _gutterPaint = Paint()
      ..color = const Color(0xFFF25C54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05;

    _gutterGlowPaint = Paint()
      ..color = const Color(0x33F25C54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.15;

    _pulseGutterPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05;

    _pulseGutterGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.15;
  }

  @override
  Body createBody() {
    final def = BodyDef()
      ..userData = this
      ..type = BodyType.static
      ..position = Vector2.zero();

    final body = world.createBody(def);
    const width = 9.0;
    const height = 16.0;

    // Static wall polygon shape segments
    final leftWall = EdgeShape()..set(Vector2(0, yOffset), Vector2(0, height + yOffset));
    final rightWall = EdgeShape()..set(Vector2(width, yOffset), Vector2(width, height + yOffset));
    final topWall = EdgeShape()..set(Vector2(0, yOffset), Vector2(width, yOffset));

    _fixtures.add(body.createFixture(FixtureDef(leftWall)..friction = 0.1));
    _fixtures.add(body.createFixture(FixtureDef(rightWall)..friction = 0.1));
    _fixtures.add(body.createFixture(FixtureDef(topWall)..friction = 0.1));

    // Gutter funneling sloped floor surfaces
    final leftGutter = EdgeShape()..set(Vector2(0, 15.2 + yOffset), Vector2(6.8, 16.0 + yOffset));
    final rightGutter = EdgeShape()..set(Vector2(width, 15.2 + yOffset), Vector2(8.2, 16.0 + yOffset));

    _leftGutterFixture = body.createFixture(FixtureDef(leftGutter)..friction = 0.1);
    _rightGutterFixture = body.createFixture(FixtureDef(rightGutter)..friction = 0.1);
    _fixtures.add(_leftGutterFixture);
    _fixtures.add(_rightGutterFixture);

    return body;
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball && game.ballSaverTimeRemaining > 0.0) {
      final myFixture = contact.fixtureA.body == body ? contact.fixtureA : contact.fixtureB;
      if (myFixture == _leftGutterFixture || myFixture == _rightGutterFixture) {
        // Trigger a medium haptic reset impact
        HapticFeedback.mediumImpact();
        game.requestShieldReset();
      }
    }
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
    final bool isShieldActive = game.ballSaverTimeRemaining > 0.0;
    Paint currentGutterPaint = _gutterPaint;
    Paint currentGutterGlowPaint = _gutterGlowPaint;

    if (isShieldActive) {
      final pulse = 0.5 + 0.5 * math.sin(game.ballSaverTimeRemaining * 15.0);
      
      _pulseGutterPaint.color = const Color(0xFF00E5FF).withValues(alpha: 0.6 + pulse * 0.4);
      _pulseGutterGlowPaint.color = const Color(0xFF00E5FF).withValues(alpha: pulse * 0.5);

      currentGutterPaint = _pulseGutterPaint;
      currentGutterGlowPaint = _pulseGutterGlowPaint;
    }

    _drawGlowingLine(canvas, Offset(0, 15.2 + yOffset), Offset(6.8, 16.0 + yOffset), currentGutterPaint, currentGutterGlowPaint);
    _drawGlowingLine(canvas, Offset(9.0, 15.2 + yOffset), Offset(8.2, 16.0 + yOffset), currentGutterPaint, currentGutterGlowPaint);
  }

  void _drawGlowingLine(Canvas canvas, Offset p1, Offset p2, Paint paint, Paint glowPaint) {
    canvas.drawLine(p1, p2, glowPaint);
    canvas.drawLine(p1, p2, paint);
  }
}
