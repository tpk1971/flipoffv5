import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
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

  /// The player's remaining lives. Starts at 10, max 15.
  final ValueNotifier<int> livesNotifier = ValueNotifier<int>(10);

  /// Whether the game is currently in a game-over state.
  final ValueNotifier<bool> isGameOverNotifier = ValueNotifier<bool>(false);

  /// Real-time FPS, computed reactively (only visible in devMode/kDebugMode).
  final ValueNotifier<double> fpsNotifier = ValueNotifier<double>(60.0);

  /// Time remaining (in seconds) for the gutter shield / ball saver protection window.
  double ballSaverTimeRemaining = 0.0;

  /// Queue of SFX asset names to be played outside the Box2D solver phase.
  final List<String> _sfxQueue = [];

  /// Enqueues an SFX to be played safely on the next main loop frame update tick.
  void queueSfx(String name) {
    _sfxQueue.add(name);
  }

  /// Resets the game to its initial state, clearing score, setting lives to 10,
  /// clearing the game over state, and reloading the first room.
  void resetGame() {
    scoreNotifier.value = 0;
    livesNotifier.value = 10;
    isGameOverNotifier.value = false;
    ballSaverTimeRemaining = 5.0;
    overlays.remove('gameOver');

    // Reset ball position and reload Room 1
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

    ball.body.setTransform(Vector2(sx, sy + yOffset), 0.0);
    ball.body.linearVelocity = Vector2.zero();
    ball.body.angularVelocity = 0.0;
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
      final currentPos = camera.viewfinder.position;
      camera.viewfinder.position = currentPos + (cameraTargetPosition - currentPos) * (5.0 * dt);
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

        // Park the ball off-screen with no speed to prevent collisions
        ball.body.setTransform(Vector2(-100.0, -100.0), 0.0);
        ball.body.linearVelocity = Vector2.zero();
        ball.body.angularVelocity = 0.0;
      } else {
        resetBallToSpawn();
        // Reset ball saver shield
        ballSaverTimeRemaining = 5.0;
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
