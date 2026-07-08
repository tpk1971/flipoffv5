import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextSpan, TextStyle, TextPainter, TextDirection;

/// A component that displays a glowing neon green "EXTRA LIFE!" text popup
/// at the center of the active room viewport, which scales up and fades out over 2 seconds.
class ExtraLifeTextPopup extends PositionComponent {
  /// The duration of the text popup animation.
  static const double duration = 2.0;

  /// Time elapsed since instantiation.
  double _elapsed = 0.0;

  /// Paint used to draw the text outline/glow.
  late final Paint _outlinePaint;

  /// Creates an ExtraLifeTextPopup centered at the specified [position].
  ExtraLifeTextPopup({required super.position})
      : super(
          anchor: Anchor.center,
          priority: 100, // Render in front of obstacles
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _outlinePaint = Paint()
      ..color = const Color(0x8800FF66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.08
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.05);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }

    // Scale up and float slightly upwards
    scale = Vector2.all(1.0 + (_elapsed / duration) * 0.4);
    position.y -= 1.0 * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate transparency fade-out
    final progress = _elapsed / duration;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    _outlinePaint.color = const Color(0xFF00FF66).withValues(alpha: alpha * 0.5);

    // Draw the "EXTRA LIFE!" text using a simple outline/stroke approach
    final textStyle = TextStyle(
      color: const Color(0xFF00FF66).withValues(alpha: alpha),
      fontSize: 28.0, // In screen-space pixels before scaling
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
    );

    final textSpan = TextSpan(
      text: 'EXTRA LIFE!',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    canvas.save();
    // Scale pixel text down to meters size in world coordinates
    canvas.scale(0.015);
    final offset = Offset(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, offset);
    canvas.restore();
  }
}

/// A component that animates a glowing neon green particle emanating
/// from the hit target's position and heading to the top-right HUD life bar.
class BonusLifeFlyer extends PositionComponent {
  /// Start position of the flyer.
  final Vector2 startPosition;

  /// Target position of the flyer (top right HUD bar coordinates).
  final Vector2 targetPosition;

  /// Duration of the flight animation.
  static const double flightDuration = 1.0;

  /// Time elapsed since flight started.
  double _elapsed = 0.0;

  /// Paint used to draw the glowing flyer core.
  late final Paint _paint;

  /// Paint used to draw the glowing flyer outline.
  late final Paint _glowPaint;

  /// Creates a BonusLifeFlyer.
  BonusLifeFlyer({
    required this.startPosition,
    required this.targetPosition,
  }) : super(
          position: startPosition.clone(),
          size: Vector2.all(0.3), // width/height is diameter, radius is 0.15
          anchor: Anchor.center,
          priority: 110,
        );

  /// Helper getter for radius.
  double get radius => size.x / 2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _paint = Paint()
      ..color = const Color(0xFF00FF66)
      ..style = PaintingStyle.fill;

    _glowPaint = Paint()
      ..color = const Color(0x8800FF66)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= flightDuration) {
      removeFromParent();
      return;
    }

    final progress = (_elapsed / flightDuration).clamp(0.0, 1.0);

    // Linear interpolation of position towards the HUD
    position.setFrom(startPosition + (targetPosition - startPosition) * progress);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _elapsed / flightDuration;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    _paint.color = const Color(0xFF00FF66).withValues(alpha: alpha);
    _glowPaint.color = const Color(0xFF00FF66).withValues(alpha: alpha * 0.4);

    // Draw glowing green neon sphere flying towards the HUD
    canvas.drawCircle(Offset.zero, radius * 1.5, _glowPaint);
    canvas.drawCircle(Offset.zero, radius, _paint);
  }
}
