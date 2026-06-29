import 'package:flame/components.dart';
import 'package:flipoff/game/components/bumper.dart';
import 'package:flipoff/game/components/double_wide_flipper.dart';
import 'package:flipoff/game/components/exit_portal.dart';
import 'package:flipoff/game/components/gutter_sensor.dart';
import 'package:flipoff/game/components/playfield_boundaries.dart';
import 'package:flipoff/game/components/target.dart';

/// A container component representing the full physical layout of a single chamber.
///
/// Builds boundaries, flipper, bumpers, targets, and the exit portal at a
/// specific vertical offset derived from the room index.
class RoomLayout extends Component {
  /// The vertical index of this room (0 for room 1, 1 for room 2, etc.).
  final int roomIndex;

  /// The parsed configuration properties for this room.
  final Map<String, dynamic> config;

  /// Creates a room layout component.
  RoomLayout({
    required this.roomIndex,
    required this.config,
  });

  /// The vertical coordinate offset for all entities in this room.
  double get yOffset => roomIndex * -16.0;

  /// The flipper instance active in this room.
  late final DoubleWideFlipper flipper;

  /// The exit portal instance active in this room.
  late final ExitPortal portal;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add boundaries with offset
    await add(PlayfieldBoundaries(yOffset: yOffset));

    // Add gutter sensor with offset
    await add(GutterSensor(yOffset: yOffset));

    // Add asymmetrical flipper with offset
    flipper = DoubleWideFlipper(initialPosition: Vector2(1.5, 13.5 + yOffset));
    await add(flipper);

    // Add bumpers
    final bumpersList = config['bumpers'] as List<dynamic>? ?? [];
    for (final bumperData in bumpersList) {
      final x = (bumperData['x'] as num).toDouble();
      final y = (bumperData['y'] as num).toDouble();
      final radius = (bumperData['radius'] as num).toDouble();
      await add(
        Bumper(
          initialPosition: Vector2(x, y + yOffset),
          radius: radius,
        ),
      );
    }

    // Add targets
    final targetsList = config['targets'] as List<dynamic>? ?? [];
    for (final targetData in targetsList) {
      final x = (targetData['x'] as num).toDouble();
      final y = (targetData['y'] as num).toDouble();
      await add(
        Target(
          initialPosition: Vector2(x, y + yOffset),
        ),
      );
    }

    // Add exit portal
    final portalData = config['portal'] as Map<String, dynamic>;
    final px = (portalData['x'] as num).toDouble();
    final py = (portalData['y'] as num).toDouble();
    final pr = (portalData['radius'] as num).toDouble();
    portal = ExitPortal(
      initialPosition: Vector2(px, py + yOffset),
      radius: pr,
    );
    await add(portal);
  }
}
