import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextSpan, TextStyle, TextPainter, TextDirection;

/// A component that displays a congratulations "LEVEL UP!" center-screen announcement.
///
/// It pulses in scale and fades out over a 2-second duration.
class LevelUpPopup extends PositionComponent {
  /// The duration of the level up popup animation.
  static const double duration = 2.0;

  /// Time elapsed since instantiation.
  double _elapsed = 0.0;

  /// Paint used to draw the text outline/glow.
  late final Paint _outlinePaint;

  /// Creates a LevelUpPopup centered at the specified [position].
  LevelUpPopup({required super.position})
      : super(
          anchor: Anchor.center,
          priority: 120, // Render in front of everything
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _outlinePaint = Paint()
      ..color = const Color(0x8800F5D4) // Neon Cyan glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.08);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }

    // Pulse size back and forth
    final pulse = 1.0 + 0.15 * (1.0 - (_elapsed / duration));
    scale = Vector2.all(pulse);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate transparency fade-out
    final progress = _elapsed / duration;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    _outlinePaint.color = const Color(0xFF00F5D4).withValues(alpha: alpha * 0.5);

    // Draw the "LEVEL UP!" text
    final textStyle = TextStyle(
      color: const Color(0xFF00F5D4).withValues(alpha: alpha),
      fontSize: 36.0, // In screen-space pixels before scaling
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
    );

    final textSpan = TextSpan(
      text: 'LEVEL UP!',
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
