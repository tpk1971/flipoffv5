import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flipoff/game/components/room_layout.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// A manager component that coordinates level configurations and room transitions.
///
/// Loads room layout specifications from JSON assets, manages objectives
/// (remaining targets), and triggers camera/position updates on transitions.
class RoomManager extends Component with HasGameReference<FlipoffGame> {
  /// Creates the room manager.
  RoomManager();

  /// The active room layout component currently added to the world.
  RoomLayout? _activeLayout;

  /// Gets the currently active room layout.
  RoomLayout? get activeLayout => _activeLayout;

  /// The current room identifier (e.g. 'room_1', 'room_2').
  String _currentRoomId = 'room_1';

  /// Gets the current room identifier.
  String get currentRoomId => _currentRoomId;

  /// The count of targets remaining to be destroyed in the current room.
  int _remainingTargets = 0;

  /// Gets the count of remaining targets.
  int get remainingTargets => _remainingTargets;

  /// Internal flag indicating if a room loading operation is pending.
  bool _shouldLoadNextRoom = false;

  /// Cached room ID to load during the next update cycle.
  String? _nextRoomIdToLoad;

  /// Cached configuration map to load during the next update cycle.
  Map<String, dynamic>? _nextRoomConfig;

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
  void onPortalEntered() {
    final nextRoomId = _activeLayout?.config['portal']['nextRoomIdId'] ??
        _activeLayout?.config['portal']['nextRoomId'] ??
        'room_1';
    requestRoomTransition(nextRoomId);
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
  }

  /// Helper method to execute structural updates and room loading asynchronously.
  Future<void> _performTransition(String nextRoomId, Map<String, dynamic> config) async {
    final oldLayout = _activeLayout;
    _currentRoomId = nextRoomId;

    final roomIndex = nextRoomId == 'room_1' ? 0 : 1;
    _remainingTargets = (config['targets'] as List<dynamic>? ?? []).length;

    // Create and add the new layout
    final newLayout = RoomLayout(roomIndex: roomIndex, config: config);
    await game.world.add(newLayout);
    _activeLayout = newLayout;
    game.activeTheme = newLayout.theme;

    if (_remainingTargets == 0) {
      newLayout.portal.unlock();
    }

    // Position camera Y coordinate
    game.cameraTargetPosition = Vector2(4.5, 8.0 + roomIndex * -16.0);

    // Reposition ball
    final spawnPos = config['spawnPosition'] as List<dynamic>;
    final sx = (spawnPos[0] as num).toDouble();
    final sy = (spawnPos[1] as num).toDouble();

    game.ball.body.setTransform(Vector2(sx, sy + roomIndex * -16.0), 0.0);
    game.ball.body.linearVelocity = Vector2.zero();
    game.ball.body.angularVelocity = 0.0;

    // Remove old layout
    if (oldLayout != null) {
      oldLayout.removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

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
