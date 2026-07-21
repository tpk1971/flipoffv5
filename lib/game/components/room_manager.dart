import 'dart:convert';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flipoff/game/components/room_layout.dart';
import 'package:flipoff/game/components/level_up_popup.dart';
import 'package:flipoff/game/audio_controller.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// Manages level transitions, room lifecycle, and loading room JSON configs.
class RoomManager extends Component with HasGameReference<FlipoffGame> {
  /// The active room layout containing all room physical entities.
  RoomLayout? _activeLayout;

  /// The active room layout containing all room physical entities.
  RoomLayout? get activeLayout => _activeLayout;

  /// The unique room ID of the currently loaded chamber (e.g. 'room_1').
  String _currentRoomId = '';

  /// The unique room ID of the currently loaded chamber (e.g. 'room_1').
  String get currentRoomId => _currentRoomId;

  /// Remaining targets in the room before exit portal unlocks.
  int _remainingTargets = 0;

  /// The number of remaining targets to destroy in this room.
  int get remainingTargets => _remainingTargets;

  /// Flags if a room transition is currently queued.
  bool _shouldLoadNextRoom = false;

  /// Cached next room ID to load.
  String? _nextRoomIdToLoad;

  /// Cached next room JSON configuration.
  Map<String, dynamic>? _nextRoomConfig;

  // Cinematic level transition fields
  bool _isTransitionPending = false;
  double _transitionHoldTimer = 0.0;
  String _pendingRoomId = '';

  bool _isCameraPanning = false;

  /// Exposes if the camera is currently in panning transition state.
  bool get isCameraPanning => _isCameraPanning;

  double _cameraPanProgress = 0.0;
  late Vector2 _panStartPos;
  late Vector2 _panTargetPos;

  // Deferred spawn cache
  double _deferredSpawnX = 4.5;
  double _deferredSpawnY = 3.0;
  int _deferredRoomIndex = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Pre-load Room 1 instantly on startup
    await _loadRoomSync('room_1');
  }

  /// Triggers a target hit registration, decrementing the count and unlocking the portal.
  void onTargetHit() {
    if (_remainingTargets > 0) {
      _remainingTargets--;
      if (_remainingTargets == 0) {
        _activeLayout?.portal.unlock();
      }
    }
  }

  /// Callback when the ball successfully triggers the active exit portal.
  int _carriedBallCount = 1;
  int _deferredCarriedBallCount = 1;

  /// Flags if a transition hold is currently pending.
  bool get isTransitionPending => _isTransitionPending;

  /// Callback when the ball successfully triggers the active exit portal.
  void onPortalEntered() {
    final nextRoomId = _activeLayout?.config['portal']['nextRoomIdId'] ??
        _activeLayout?.config['portal']['nextRoomId'] ??
        'room_1';

    // Capture the count of active balls currently in play to persist across room transitions
    _carriedBallCount = math.max(1, game.activeBalls.length);

    // Initiate Phase 1: 1.0 second hold on current room before panning
    _pendingRoomId = nextRoomId;
    _isTransitionPending = true;
    _transitionHoldTimer = 1.0;

    // Freeze primary ball in portal to avoid falling/rolling
    game.ball.body.linearVelocity = Vector2.zero();
    game.ball.body.angularVelocity = 0.0;

    // Spawn "LEVEL UP!" on the current room viewport
    final currentRoomIndex = _currentRoomId == 'room_1' ? 0 : 1;
    final centerPos = Vector2(4.5, 8.0 + currentRoomIndex * -16.0);
    game.world.add(LevelUpPopup(position: centerPos));
  }

  /// Queues a transition to load the specified [nextRoomId] on the next frame.
  void requestRoomTransition(String nextRoomId) {
    if (_shouldLoadNextRoom) return;

    // Load the JSON asset asynchronously, then cache it to process inside the update loop
    rootBundle.loadString('assets/levels/$nextRoomId.json').then((jsonString) {
      final config = json.decode(jsonString) as Map<String, dynamic>;
      _nextRoomIdToLoad = nextRoomId;
      _nextRoomConfig = config;
      _shouldLoadNextRoom = true;
    });
  }

  /// Executes the transition to load a room layout synchronously.
  Future<void> _loadRoomSync(String roomId) async {
    final jsonString = await rootBundle.loadString('assets/levels/$roomId.json');
    final config = json.decode(jsonString) as Map<String, dynamic>;
    _currentRoomId = roomId;

    final roomIndex = roomId == 'room_1' ? 0 : 1;
    _remainingTargets = (config['targets'] as List<dynamic>? ?? []).length;

    // Build and add the room layout
    final layout = RoomLayout(roomIndex: roomIndex, config: config);
    await game.world.add(layout);
    _activeLayout = layout;
    game.activeTheme = layout.theme;

    if (_remainingTargets == 0) {
      layout.portal.unlock();
    }

    // Position the camera Y target center
    game.cameraTargetPosition = Vector2(4.5, 8.0 + roomIndex * -16.0);
    game.camera.viewfinder.position = game.cameraTargetPosition;

    // Reposition the ball to the room's spawn coordinate
    final spawnPos = config['spawnPosition'] as List<dynamic>;
    final sx = (spawnPos[0] as num).toDouble();
    final sy = (spawnPos[1] as num).toDouble();

    // Check if ball body exists (might not be created during initial onLoad of game)
    if (game.ball.isMounted) {
      game.ball.body.setTransform(Vector2(sx, sy + roomIndex * -16.0), 0.0);
      game.ball.body.linearVelocity = Vector2.zero();
      game.ball.body.angularVelocity = 0.0;
    }

    // Auto-rotate and play music loop for the starting level
    GameAudioController.instance.playMusicForRoom(roomIndex);
  }

  /// Helper method to execute structural updates and room loading asynchronously.
  Future<void> _performTransition(String nextRoomId, Map<String, dynamic> config) async {
    final oldLayout = _activeLayout;
    _currentRoomId = nextRoomId;

    final roomIndex = nextRoomId == 'room_1' ? 0 : 1;
    _remainingTargets = (config['targets'] as List<dynamic>? ?? []).length;

    // Save carried ball count for deferred spawn
    _deferredCarriedBallCount = _carriedBallCount;

    // Create and add the new layout
    final newLayout = RoomLayout(roomIndex: roomIndex, config: config);
    await game.world.add(newLayout);
    _activeLayout = newLayout;
    game.activeTheme = newLayout.theme;

    if (_remainingTargets == 0) {
      newLayout.portal.unlock();
    }

    // Initiate Phase 2: Start 1.0s Camera Easing Pan to new target viewport
    _panStartPos = game.camera.viewfinder.position.clone();
    _panTargetPos = Vector2(4.5, 8.0 + roomIndex * -16.0);
    _isCameraPanning = true;
    _cameraPanProgress = 0.0;
    game.cameraTargetPosition = _panTargetPos;

    // Parse spawn position and cache it to defer ball spawning until pan completes
    final spawnPos = config['spawnPosition'] as List<dynamic>;
    _deferredSpawnX = (spawnPos[0] as num).toDouble();
    _deferredSpawnY = (spawnPos[1] as num).toDouble();
    _deferredRoomIndex = roomIndex;

    // Hide/park the ball off-screen with no speed to prevent early collision
    game.ball.body.setTransform(Vector2(-100.0, -100.0), 0.0);
    game.ball.body.linearVelocity = Vector2.zero();
    game.ball.body.angularVelocity = 0.0;

    // Remove old layout
    if (oldLayout != null) {
      oldLayout.removeFromParent();
    }

    // Play loop rotation for the new room
    GameAudioController.instance.playMusicForRoom(roomIndex);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle initial hold timer (Phase 1)
    if (_isTransitionPending) {
      // Pin ball in place during current level popup display
      game.ball.body.linearVelocity = Vector2.zero();
      game.ball.body.angularVelocity = 0.0;

      _transitionHoldTimer -= dt;
      if (_transitionHoldTimer <= 0.0) {
        _isTransitionPending = false;
        requestRoomTransition(_pendingRoomId);
      }
    }

    // Handle easing camera pan (Phase 2)
    if (_isCameraPanning) {
      _cameraPanProgress += dt; // 1.0 second duration pan
      final double t = _cameraPanProgress.clamp(0.0, 1.0);

      // Cubic Hermite Ease-In-Ease-Out: 3t^2 - 2t^3
      final double eased = t * t * (3.0 - 2.0 * t);
      game.camera.viewfinder.position = _panStartPos + (_panTargetPos - _panStartPos) * eased;

      if (_cameraPanProgress >= 1.0) {
        _isCameraPanning = false;

        // Pan complete, launch primary ball and trigger 5s gutter shield protection
        game.ball.body.setTransform(Vector2(_deferredSpawnX, _deferredSpawnY + _deferredRoomIndex * -16.0), 0.0);
        game.ball.body.linearVelocity = Vector2.zero();
        game.ball.body.angularVelocity = 0.0;
        game.ballSaverTimeRemaining = 5.0;

        // Persist multiball: if carried ball count > 1, release additional balls
        if (_deferredCarriedBallCount > 1) {
          game.triggerMultiball(totalBalls: _deferredCarriedBallCount);
        }
      }
    }

    // Process queued room transition safely inside the update loop (unlocked physics state)
    if (_shouldLoadNextRoom && _nextRoomIdToLoad != null && _nextRoomConfig != null) {
      _shouldLoadNextRoom = false;
      final nextRoomId = _nextRoomIdToLoad!;
      final config = _nextRoomConfig!;

      _nextRoomIdToLoad = null;
      _nextRoomConfig = null;

      // Execute transition asynchronously
      _performTransition(nextRoomId, config);
    }
  }
}
