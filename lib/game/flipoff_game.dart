import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flipoff/game/components/background_grid.dart';
import 'package:flipoff/game/components/ball.dart';
import 'package:flipoff/game/components/room_manager.dart';

/// The core Flame Forge2D game class for Flipoff: Snap.
///
/// This game class coordinates physics simulation, manages the component tree,
/// handles touch gestures, and configures the camera viewport zoom.
class FlipoffGame extends Forge2DGame with TapCallbacks {
  /// Initializes the game with the design spec gravity of 7.5.
  FlipoffGame() : super(gravity: Vector2(0, 7.5));

  @override
  Color backgroundColor() => const Color(0xFF0D0E15);

  /// Reference to the active pinball.
  late final Ball ball;

  /// Reference to the active room manager.
  late final RoomManager roomManager;

  /// The active room theme config, defining 90's retro neon styling.
  RoomTheme activeTheme = const RoomTheme(
    gridColor: Color(0xFF00F5D4),   // Neon Cyan
    bumperColor: Color(0xFFFF007F), // Neon Hot Pink
    flipperColor: Color(0xFFFF9F1C), // Neon Orange
    targetColor: Color(0xFF00F5D4),  // Cyan
  );

  /// Target camera viewport center coordinates (for smooth vertical transitions).
  Vector2 cameraTargetPosition = Vector2(4.5, 8.0);

  /// Internal flag to defer ball reset outside the physics contact solver phase.
  bool _shouldResetBall = false;

  /// Flags the ball to be reset to its spawn point on the next update frame.
  void requestBallReset() {
    _shouldResetBall = true;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Center the camera viewfinder on the middle of the first 9x16 playfield
    camera.viewfinder.position = Vector2(4.5, 8.0);
    camera.viewfinder.anchor = Anchor.center;

    // Add the background grid component
    await world.add(BackgroundGrid());

    // Spawn the persistent ball
    ball = Ball(initialPosition: Vector2(4.5, 3.0));
    await world.add(ball);

    // Initialize and add the RoomManager
    roomManager = RoomManager();
    await world.add(roomManager);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Scale camera zoom dynamically so that the 9x16 meters playfield
    // fits within the screen's safe boundaries.
    final zoomX = size.x / 9.0;
    final zoomY = size.y / 16.0;
    camera.viewfinder.zoom = math.min(zoomX, zoomY);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    roomManager.activeLayout?.flipper.activate();
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    roomManager.activeLayout?.flipper.deactivate();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    roomManager.activeLayout?.flipper.deactivate();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Smoothly pan camera viewfinder toward target position using the explicit setter
    final currentPos = camera.viewfinder.position;
    camera.viewfinder.position = currentPos + (cameraTargetPosition - currentPos) * (5.0 * dt);

    if (_shouldResetBall) {
      _shouldResetBall = false;

      final roomIndex = roomManager.currentRoomId == 'room_1' ? 0 : 1;
      final yOffset = roomIndex * -16.0;

      final spawnPos = roomManager.activeLayout?.config['spawnPosition'] as List<dynamic>?;
      final sx = spawnPos != null ? (spawnPos[0] as num).toDouble() : 4.5;
      final sy = spawnPos != null ? (spawnPos[1] as num).toDouble() : 3.0;

      ball.body.setTransform(Vector2(sx, sy + yOffset), 0.0);
      ball.body.linearVelocity = Vector2.zero();
      ball.body.angularVelocity = 0.0;
    }
  }
}

/// Defines a structured theme color palette for a room layout.
class RoomTheme {
  /// The color of the background playfield grid lines.
  final Color gridColor;

  /// The primary glowing color for bumpers.
  final Color bumperColor;

  /// The primary glowing color for flippers.
  final Color flipperColor;

  /// The primary glowing color for targets.
  final Color targetColor;

  /// Creates a room theme palette.
  const RoomTheme({
    required this.gridColor,
    required this.bumperColor,
    required this.flipperColor,
    required this.targetColor,
  });
}
