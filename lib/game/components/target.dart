import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flipoff/game/components/ball.dart';
import 'package:flipoff/game/components/score_popup.dart';
import 'package:flipoff/game/components/spark_particle.dart';
import 'package:flipoff/game/components/bonus_life_effects.dart';
import 'package:flipoff/game/flipoff_game.dart';
import 'package:flipoff/game/components/room_manager.dart';

/// A static crystal target component that the ball collides with.
///
/// Hitting this target deactivates/destroys it, registers scoring,
/// and updates the active level objective or triggers multiball.
/// Supports multi-step targets requiring multiple hits before destruction.
class Target extends BodyComponent<FlipoffGame> with ContactCallbacks {
  /// The local position of this target in the room's coordinate system.
  final Vector2 initialPosition;

  /// Whether this target contains a bonus life.
  final bool isBonusLife;

  /// Whether this target triggers a multiball frenzy upon contact.
  final bool isMultiballTarget;

  /// The total number of hits required to destroy this target.
  final int maxHits;

  /// The number of remaining hits required before this target is destroyed.
  int remainingHits;

  /// Creates a target component at the specified [initialPosition].
  ///
  /// [initialPosition] defines the world space coordinates.
  /// [isBonusLife] sets if an extra life is awarded on destruction.
  /// [isMultiballTarget] sets if a multiball frenzy triggers on contact.
  /// [maxHits] sets the total required hits before destruction (defaults to 1).
  Target({
    required this.initialPosition,
    this.isBonusLife = false,
    this.isMultiballTarget = false,
    this.maxHits = 1,
  }) : remainingHits = maxHits;

  /// The glassmorphic/neon fill paint for the target.
  late final Paint _paint;

  /// The glow outline paint for the target.
  late final Paint _borderPaint;

  /// Paint for multi-step hit indicator dots.
  late final Paint _stepDotPaint;

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

    _stepDotPaint = Paint()
      ..style = PaintingStyle.fill;
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
    // Draw multiball targets in glowing gold, bonus targets in neon green, standard targets in room theme color
    final themeColor = isMultiballTarget
        ? const Color(0xFFFFD700)
        : (isBonusLife ? const Color(0xFF00FF66) : game.activeTheme.targetColor);

    // Opacity scales with remaining hits ratio
    final healthRatio = maxHits > 0 ? (remainingHits / maxHits).clamp(0.2, 1.0) : 1.0;
    _paint.color = themeColor.withValues(alpha: 0.4 * healthRatio + 0.2); // Glass fill
    _borderPaint.color = themeColor; // Full glowing neon border

    // Draw the core circle
    canvas.drawCircle(Offset.zero, 0.3, _paint);
    // Draw the neon glow border outline
    canvas.drawCircle(Offset.zero, 0.3, _borderPaint);

    // Render multi-hit step indicators (outer glowing dots or ring segments)
    if (maxHits > 1) {
      const double dotRadius = 0.04;
      const double ringRadius = 0.38;
      final double angleStep = (2 * math.pi) / maxHits;

      for (int i = 0; i < maxHits; i++) {
        final double angle = i * angleStep - (math.pi / 2); // Start at top
        final Offset dotOffset = Offset(
          ringRadius * math.cos(angle),
          ringRadius * math.sin(angle),
        );

        final bool isActiveStep = i < remainingHits;
        _stepDotPaint.color = isActiveStep ? themeColor : Colors.white24;

        canvas.drawCircle(dotOffset, dotRadius, _stepDotPaint);
      }
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball) {
      if (remainingHits <= 0) return;

      final pos = body.position.clone();
      final multiplier = game.scoreMultiplierNotifier.value;
      final themeColor = isMultiballTarget
          ? const Color(0xFFFFD700)
          : (isBonusLife ? const Color(0xFF00FF66) : game.activeTheme.targetColor);

      // Check if target requires multiple hits before breaking
      if (remainingHits > 1) {
        remainingHits--;
        final partialPoints = 50 * multiplier;
        game.scoreNotifier.value += partialPoints;

        game.world.add(ScorePopup(text: '+$partialPoints ($remainingHits/$maxHits)', position: pos));
        game.world.add(SparkParticleSystem(position: pos, color: themeColor));

        HapticFeedback.lightImpact();
        game.queueSfx('sfx_target.wav');
        return;
      }

      // Final hit: process target destruction
      remainingHits = 0;

      final basePoints = isMultiballTarget ? 250 : 100;
      final points = basePoints * multiplier;
      game.scoreNotifier.value += points;

      if (isMultiballTarget) {
        game.world.add(ScorePopup(text: '+$points MULTIBALL!', position: pos));
        game.triggerMultiball();
      } else if (isBonusLife) {
        final roomIndex = (game.isLoaded && game.children.whereType<RoomManager>().isNotEmpty && game.roomManager.currentRoomId == 'room_2') ? 1 : 0;
        final yOffset = roomIndex * -16.0;

        // Spawn "+EXTRA LIFE!" centered popup text
        final centerPos = Vector2(4.5, 8.0 + yOffset);
        game.world.add(ExtraLifeTextPopup(position: centerPos));

        // Spawn flying green neon sphere towards HUD life bar
        final hudPos = Vector2(8.5, 0.8 + yOffset);
        game.world.add(BonusLifeFlyer(startPosition: pos, targetPosition: hudPos));

        if (game.livesNotifier.value < 15) {
          game.livesNotifier.value++;
        } else {
          // Max lives bonus points
          game.scoreNotifier.value += 500 * multiplier;
          game.world.add(ScorePopup(text: '+${500 * multiplier} MAX LIVES', position: pos));
        }
      } else {
        game.world.add(ScorePopup(text: '+$points', position: pos));
      }

      // Spawn radial spark particles utilizing active theme color
      game.world.add(SparkParticleSystem(position: pos, color: themeColor));

      // Trigger light haptic impact feedback
      HapticFeedback.lightImpact();
      game.queueSfx('sfx_target.wav');

      // Safe deferred removal from the Flame component tree
      removeFromParent();

      // Notify the active room manager
      if (game.isLoaded && game.children.whereType<RoomManager>().isNotEmpty) {
        game.roomManager.onTargetHit();
      }
    }
  }
}
