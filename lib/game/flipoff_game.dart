import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
import 'package:flutter/painting.dart' show Color;
import 'package:flipoff/game/components/background_grid.dart';
import 'package:flipoff/game/components/ball.dart';
import 'package:flipoff/game/components/room_manager.dart';
import 'package:flipoff/game/components/starfield.dart';
import 'package:flipoff/game/components/score_popup.dart';
import 'package:flipoff/game/services/user_profile_service.dart';
import 'package:flipoff/game/audio_controller.dart';

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

  /// The player's current score, tracked reactively.
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);

  /// The player's remaining lives. Starts at 3, max 15.
  final ValueNotifier<int> livesNotifier = ValueNotifier<int>(3);

  /// The active score multiplier (e.g. 1x default, 3x during 3-ball multiball).
  final ValueNotifier<int> scoreMultiplierNotifier = ValueNotifier<int>(1);

  /// Whether the game is currently in a game-over state.
  final ValueNotifier<bool> isGameOverNotifier = ValueNotifier<bool>(false);

  /// Real-time FPS, computed reactively (only visible in devMode/kDebugMode).
  final ValueNotifier<double> fpsNotifier = ValueNotifier<double>(60.0);

  /// Time remaining (in seconds) for the gutter shield / ball saver protection window.
  double ballSaverTimeRemaining = 0.0;

  /// Queue of SFX asset names to be played outside the Box2D solver phase.
  final List<String> _sfxQueue = [];

  /// Returns all currently active [Ball] instances mounted in the game world.
  List<Ball> get activeBalls => world.children.whereType<Ball>().toList();

  /// Gets the primary lead ball for camera tracking and single-ball physics references.
  Ball get leadBall {
    final balls = activeBalls;
    if (balls.isEmpty) return ball;
    // Follow the ball closest to the flippers (highest y coordinate)
    return balls.reduce((a, b) => a.body.position.y > b.body.position.y ? a : b);
  }

  /// Enqueues an SFX to be played safely on the next main loop frame update tick.
  void queueSfx(String name) {
    _sfxQueue.add(name);
  }

  /// Triggers a Multiball Frenzy mode, spawning extra pinballs at the room spawn point
  /// and increasing the active score multiplier.
  void triggerMultiball({int totalBalls = 3}) {
    if (isGameOverNotifier.value) return;

    final currentCount = activeBalls.length;
    final ballsToSpawn = math.max(0, totalBalls - currentCount);

    if (ballsToSpawn == 0) return;

    final roomIndex = roomManager.currentRoomId == 'room_1' ? 0 : 1;
    final yOffset = roomIndex * -16.0;
    final spawnPos = roomManager.activeLayout?.config['spawnPosition'] as List<dynamic>?;
    final sx = spawnPos != null ? (spawnPos[0] as num).toDouble() : 4.5;
    final sy = spawnPos != null ? (spawnPos[1] as num).toDouble() : 3.0;

    final basePos = Vector2(sx, sy + yOffset);

    // Dynamic initial impulse vectors for extra spawned balls
    final impulses = [
      Vector2(-2.5, 3.0),
      Vector2(2.5, 3.0),
    ];

    for (int i = 0; i < ballsToSpawn; i++) {
      final extraBall = Ball(initialPosition: basePos.clone());
      world.add(extraBall);

      // Apply initial impulse after physics body is created
      final impulse = i < impulses.length ? impulses[i] : Vector2(0, 2.0);
      Future.microtask(() {
        if (extraBall.isMounted) {
          extraBall.body.applyLinearImpulse(impulse);
        }
      });
    }

    scoreMultiplierNotifier.value = currentCount + ballsToSpawn;
    queueSfx('sfx_multiball.wav');
    world.add(ScorePopup(text: '3x MULTIBALL!', position: Vector2(4.5, 8.0 + yOffset)));
  }

  /// Resets the game to its initial state, clearing score, setting lives to 3,
  /// clearing the game over state, and reloading the first room.
  void resetGame() {
    scoreNotifier.value = 0;
    livesNotifier.value = 3;
    scoreMultiplierNotifier.value = 1;
    isGameOverNotifier.value = false;
    ballSaverTimeRemaining = 5.0;
    overlays.remove('gameOver');

    // Remove any extra multiball instances
    final balls = activeBalls;
    for (int i = 1; i < balls.length; i++) {
      balls[i].removeFromParent();
    }

    // Reset primary ball position and reload Room 1
    roomManager.requestRoomTransition('room_1');
  }

  /// Target camera viewport center coordinates (for smooth vertical transitions).
  Vector2 cameraTargetPosition = Vector2(4.5, 8.0);

  /// Internal flag to defer ball reset outside the physics contact solver phase.
  bool _shouldResetBall = false;

  /// Internal flag to defer ball shield reset outside the physics contact solver phase.
  bool _shouldShieldResetBall = false;

  /// Accumulator for calculating frame rate times.
  double _fpsTime = 0.0;

  /// Counter for frame count.
  int _fpsFrames = 0;

  /// Flags the ball to be reset to its spawn point on the next update frame.
  void requestBallReset() {
    _shouldResetBall = true;
  }

  /// Flags the ball to be reset to its spawn point using shield protection on the next update frame.
  void requestShieldReset() {
    _shouldShieldResetBall = true;
  }

  /// Resets the ball to the active room's spawn coordinate.
  void resetBallToSpawn() {
    final roomIndex = roomManager.currentRoomId == 'room_1' ? 0 : 1;
    final yOffset = roomIndex * -16.0;

    final spawnPos = roomManager.activeLayout?.config['spawnPosition'] as List<dynamic>?;
    final sx = spawnPos != null ? (spawnPos[0] as num).toDouble() : 4.5;
    final sy = spawnPos != null ? (spawnPos[1] as num).toDouble() : 3.0;

    final primary = activeBalls.isNotEmpty ? activeBalls.first : ball;
    primary.body.setTransform(Vector2(sx, sy + yOffset), 0.0);
    primary.body.linearVelocity = Vector2.zero();
    primary.body.angularVelocity = 0.0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Center the camera viewfinder on the middle of the first 9x16 playfield
    camera.viewfinder.position = Vector2(4.5, 8.0);
    camera.viewfinder.anchor = Anchor.center;

    // Add the parallax starfield component
    await world.add(Starfield());

    // Add the background grid component
    await world.add(BackgroundGrid());

    // Spawn the persistent ball
    ball = Ball(initialPosition: Vector2(4.5, 3.0));
    await world.add(ball);
    ballSaverTimeRemaining = 5.0;

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
    if (isGameOverNotifier.value) return;
    super.onTapDown(event);
    roomManager.activeLayout?.flipper.activate();
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isGameOverNotifier.value) return;
    super.onTapUp(event);
    roomManager.activeLayout?.flipper.deactivate();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (isGameOverNotifier.value) return;
    super.onTapCancel(event);
    roomManager.activeLayout?.flipper.deactivate();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Smoothly pan camera viewfinder toward target position using the explicit setter (skip if roomManager is easing)
    if (!roomManager.isCameraPanning) {
      final target = leadBall.body.position;
      final roomIndex = roomManager.currentRoomId == 'room_1' ? 0 : 1;
      final yOffset = roomIndex * -16.0;
      final clampedY = target.y.clamp(yOffset + 4.0, yOffset + 12.0);
      final cameraTarget = Vector2(4.5, clampedY);
      final currentPos = camera.viewfinder.position;
      camera.viewfinder.position = currentPos + (cameraTarget - currentPos) * (5.0 * dt);
    }

    // Compute FPS in debug/devMode
    _fpsFrames++;
    _fpsTime += dt;
    if (_fpsTime >= 0.5) {
      fpsNotifier.value = _fpsFrames / _fpsTime;
      _fpsFrames = 0;
      _fpsTime = 0.0;
    }

    // Decrement ball saver timer
    if (ballSaverTimeRemaining > 0.0) {
      ballSaverTimeRemaining -= dt;
    }

    // Process enqueued SFX triggers outside Box2D solver phase
    if (_sfxQueue.isNotEmpty) {
      for (final sfx in _sfxQueue) {
        GameAudioController.instance.playSfx(sfx);
      }
      _sfxQueue.clear();
    }

    // Check if any ball has escaped the playfield boundaries
    _checkBallOutOfBounds();

    if (_shouldShieldResetBall) {
      _shouldShieldResetBall = false;
      resetBallToSpawn();
      world.add(ScorePopup(text: 'SHIELD RESET', position: ball.body.position.clone()));
    }

    if (_shouldResetBall) {
      _shouldResetBall = false;

      // Deduct one life
      if (livesNotifier.value > 0) {
        livesNotifier.value--;
      }

      if (livesNotifier.value == 0) {
        // Trigger Game Over
        isGameOverNotifier.value = true;
        overlays.add('gameOver');

        // Record and submit the final score to local & global leaderboards
        UserProfileService.instance.recordScore(scoreNotifier.value);
        UserProfileService.instance.submitGlobalScore(scoreNotifier.value);

        // Park all active balls off-screen with no speed to prevent collisions
        for (final b in activeBalls) {
          b.body.setTransform(Vector2(-100.0, -100.0), 0.0);
          b.body.linearVelocity = Vector2.zero();
          b.body.angularVelocity = 0.0;
        }
      } else {
        resetBallToSpawn();
        // Reset ball saver shield
        ballSaverTimeRemaining = 5.0;
      }
    }
  }

  /// Checks if any active ball has escaped the playfield boundaries.
  ///
  /// Monitors each ball's position. If multiple balls are in play (Multiball Mode),
  /// an escaped ball is removed without deducting a life, reducing the score multiplier.
  /// If only one ball remains, standard life deduction and ball reset/game over occurs.
  void _checkBallOutOfBounds() {
    // If the game is already in a game-over state, bypass checks
    if (isGameOverNotifier.value) return;

    final currentBalls = activeBalls;
    if (currentBalls.isEmpty) return;

    // The horizontal boundaries of the playfield (0.0 to 9.0 meters)
    const minX = -1.5;
    const maxX = 10.5;

    // The vertical boundaries depend on the active room index
    final roomIndex = roomManager.currentRoomId == 'room_1' ? 0 : 1;
    final yOffset = roomIndex * -16.0;

    // Playfield height is 16 meters. Allow a threshold below the bottom drain and above the ceiling
    final minY = yOffset - 2.5;
    final maxY = yOffset + 18.5;

    for (final b in currentBalls) {
      if (!b.isMounted) continue;
      final pos = b.body.position;

      if (pos.x < minX || pos.x > maxX || pos.y < minY || pos.y > maxY) {
        debugPrint('FlipoffGame: Ball escaped boundary at (${pos.x.toStringAsFixed(2)}, ${pos.y.toStringAsFixed(2)}).');

        if (ballSaverTimeRemaining > 0.0) {
          requestShieldReset();
        } else if (currentBalls.length > 1) {
          // Multiball drain safety: remove individual ball without deducting life
          queueSfx('sfx_gutter.wav');
          b.removeFromParent();
          scoreMultiplierNotifier.value = math.max(1, currentBalls.length - 1);
        } else {
          // Final ball drain: deduct 1 life
          queueSfx('sfx_gutter.wav');
          requestBallReset();
        }
      }
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
