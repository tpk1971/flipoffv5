import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart' show TextPainter, TextSpan, TextStyle, FontWeight;

/// A transient text popup that floats upward and fades out.
///
/// Typically spawned when the ball collides with a target.
class ScorePopup extends PositionComponent {
  /// The text message to display (e.g. "+100").
  final String text;

  /// Creates a score popup component with the specified [text] at [position].
  ScorePopup({
    required this.text,
    required Vector2 position,
  }) : super(
          position: position,
          anchor: Anchor.center,
          priority: 50, // Render in front of obstacles
        );

  /// Total duration of the animation in seconds.
  static const double _duration = 0.6; // 600ms

  /// Current time elapsed in seconds.
  double _elapsed = 0.0;

  /// The TextPainter used to layout and render the text.
  late final TextPainter _textPainter;

  @override
  void onMount() {
    super.onMount();

    // Setup TextPainter with high-contrast glowing styling
    _textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFFD166), // Glowing neon gold
          fontWeight: FontWeight.bold,
          fontSize: 0.35, // Scaled to Forge2D physics coordinate system
          shadows: [
            Shadow(
              blurRadius: 4.0,
              color: Color(0xFFFFD166),
              offset: Offset.zero,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= _duration) {
      removeFromParent();
    } else {
      // Float upward in the Forge2D world coordinates
      position.y -= 1.2 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate opacity (fade out linearly)
    final double opacity = (1.0 - (_elapsed / _duration)).clamp(0.0, 1.0);

    canvas.save();
    // Offset translation to center the text
    canvas.translate(-_textPainter.width / 2, -_textPainter.height / 2);

    // Save layer to apply global opacity fade to TextPainter drawing
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, _textPainter.width, _textPainter.height),
      Paint()..color = Color.fromARGB((opacity * 255).toInt(), 255, 255, 255),
    );
    _textPainter.paint(canvas, Offset.zero);
    canvas.restore(); // Restore layer
    canvas.restore(); // Restore translation
  }
}
