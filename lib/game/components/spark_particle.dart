import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

/// A single spark configuration in the particle system.
class Spark {
  /// The local position of the spark.
  final Vector2 position;

  /// The velocity vector of the spark.
  final Vector2 velocity;

  /// The render color of the spark.
  final Color color;

  /// Current alpha opacity decay level.
  double alpha = 1.0;

  /// Creates a spark particle.
  Spark({
    required this.position,
    required this.velocity,
    required this.color,
  });

  /// Updates the spark position and decays its opacity.
  void update(double dt) {
    position.add(velocity * dt);
    alpha -= 2.2 * dt; // Fade out over ~450ms
  }
}

/// A lightweight custom particle component that spawns a radial burst of neon sparks.
class SparkParticleSystem extends PositionComponent {
  /// The count of sparks to spawn.
  final int count;

  /// The color of the sparks.
  final Color color;

  /// Internal list of active sparks.
  final List<Spark> _sparks = [];

  /// Creates the spark particle system at [position] with [count] sparks of [color].
  SparkParticleSystem({
    required Vector2 position,
    this.count = 12,
    required this.color,
  }) : super(position: position, priority: 40);

  @override
  void onMount() {
    super.onMount();
    final random = math.Random();
    for (int i = 0; i < count; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      // Speed in physics meters per second
      final double speed = 1.5 + random.nextDouble() * 2.5;
      final velocity = Vector2(math.cos(angle) * speed, math.sin(angle) * speed);
      _sparks.add(
        Spark(
          position: Vector2.zero(),
          velocity: velocity,
          color: color,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final spark in _sparks) {
      spark.update(dt);
    }
    _sparks.removeWhere((spark) => spark.alpha <= 0.0);
    if (_sparks.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final spark in _sparks) {
      if (spark.alpha <= 0.0) continue;
      final paint = Paint()
        ..color = spark.color.withValues(alpha: spark.alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      // Draw small sparks as circles in Forge2D coordinate space
      canvas.drawCircle(Offset(spark.position.x, spark.position.y), 0.05, paint);
    }
  }
}
