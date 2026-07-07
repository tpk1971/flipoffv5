import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// Represents a single star in the parallax starfield.
class _Star {
  Vector2 position;
  final double speed;
  final double radius;
  final double opacity;

  _Star({
    required this.position,
    required this.speed,
    required this.radius,
    required this.opacity,
  });
}

/// A component that renders a scrolling multi-layered parallax starfield.
///
/// Stars scroll slowly downwards, wrapping vertically from bottom to top,
/// and dynamically tint to the active room's grid theme color.
class Starfield extends PositionComponent with HasGameReference<FlipoffGame> {
  /// Creates the parallax starfield component.
  Starfield() : super(priority: -150);

  /// The list of stars to scroll and render.
  final List<_Star> _stars = [];

  /// Random generator for star distribution.
  final math.Random _random = math.Random();

  /// Paint used to render the stars.
  late final Paint _paint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _paint = Paint()..style = PaintingStyle.fill;

    // Layer 1: Deep Space (Slowest, smallest)
    _generateLayer(count: 30, minRadius: 0.02, maxRadius: 0.04, speed: 0.1, baseOpacity: 0.3);

    // Layer 2: Mid Space (Medium)
    _generateLayer(count: 20, minRadius: 0.05, maxRadius: 0.07, speed: 0.25, baseOpacity: 0.5);

    // Layer 3: Near Space (Fastest, largest)
    _generateLayer(count: 10, minRadius: 0.08, maxRadius: 0.12, speed: 0.5, baseOpacity: 0.8);
  }

  void _generateLayer({
    required int count,
    required double minRadius,
    required double maxRadius,
    required double speed,
    required double baseOpacity,
  }) {
    for (int i = 0; i < count; i++) {
      final x = _random.nextDouble() * 9.0;
      final y = (_random.nextDouble() * 32.0) - 16.0; // Random Y between -16.0 and 16.0
      final radius = minRadius + _random.nextDouble() * (maxRadius - minRadius);
      final opacity = baseOpacity * (0.8 + _random.nextDouble() * 0.4); // Add subtle opacity variance

      _stars.add(
        _Star(
          position: Vector2(x, y),
          speed: speed,
          radius: radius,
          opacity: opacity.clamp(0.0, 1.0),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final star in _stars) {
      // Move star downward
      star.position.y += star.speed * dt;

      // Wrap vertically if crossed the bottom boundary (Y: 16.0)
      if (star.position.y > 16.0) {
        star.position.y = -16.0;
        star.position.x = _random.nextDouble() * 9.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Retrieve active room theme grid color for glowing retro tinting
    final themeColor = game.activeTheme.gridColor;

    for (final star in _stars) {
      _paint.color = themeColor.withValues(alpha: star.opacity);
      canvas.drawCircle(Offset(star.position.x, star.position.y), star.radius, _paint);
    }
  }
}
