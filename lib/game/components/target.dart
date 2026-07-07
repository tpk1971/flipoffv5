import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flipoff/game/components/ball.dart';
import 'package:flipoff/game/components/score_popup.dart';
import 'package:flipoff/game/components/spark_particle.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// A static crystal target component that the ball collides with.
///
/// Hitting this target deactivates/destroys it, registers scoring,
/// and updates the active level objective.
class Target extends BodyComponent<FlipoffGame> with ContactCallbacks {
  /// The local position of this target in the room's coordinate system.
  final Vector2 initialPosition;

  /// Whether this target contains a bonus life.
  final bool isBonusLife;

  /// Creates a target component at the specified [initialPosition].
  Target({
    required this.initialPosition,
    this.isBonusLife = false,
  });

  /// The glassmorphic/neon fill paint for the target.
  late final Paint _paint;

  /// The glow outline paint for the target.
  late final Paint _borderPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _paint = Paint()
      ..color = const Color(0xAA00F5D4) // Neon Teal with glass transparency
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = const Color(0xFF00F5D4) // Full glowing neon teal border
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
    final shape = CircleShape()..radius = 0.3;

    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.4
      ..friction = 0.1;

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw bonus targets in vibrant neon green, standard targets in the active room theme color
    final themeColor = isBonusLife ? const Color(0xFF00FF66) : game.activeTheme.targetColor;
    _paint.color = themeColor.withValues(alpha: 0.6); // Semi-transparent glass fill
    _borderPaint.color = themeColor; // Full glowing neon border

    // Draw the core circle
    canvas.drawCircle(Offset.zero, 0.3, _paint);
    // Draw the neon glow border outline
    canvas.drawCircle(Offset.zero, 0.3, _borderPaint);
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball) {
      final pos = body.position.clone();
      final themeColor = isBonusLife ? const Color(0xFF00FF66) : game.activeTheme.targetColor;

      // Award base score
      game.scoreNotifier.value += 100;

      if (isBonusLife) {
        if (game.livesNotifier.value < 15) {
          game.livesNotifier.value++;
          game.world.add(ScorePopup(text: '+1 LIFE', position: pos));
        } else {
          // Max lives bonus points
          game.scoreNotifier.value += 500;
          game.world.add(ScorePopup(text: '+500 MAX LIVES', position: pos));
        }
      } else {
        game.world.add(ScorePopup(text: '+100', position: pos));
      }

      // Spawn radial spark particles utilizing active theme color
      game.world.add(SparkParticleSystem(position: pos, color: themeColor));

      // Trigger light haptic impact feedback
      HapticFeedback.lightImpact();

      // Safe deferred removal from the Flame component tree
      removeFromParent();

      // Notify the active room manager
      game.roomManager.onTargetHit();
    }
  }
}
