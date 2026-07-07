import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// A component that renders the static neon grid background for both rooms.
///
/// Draws the `bg_neon_grid.png` asset tiled vertically across Room 1 and Room 2.
class BackgroundGrid extends PositionComponent with HasGameReference<FlipoffGame> {
  /// Creates the background grid component.
  BackgroundGrid() : super(priority: -100);

  /// The sprite representation of the neon grid background.
  late final Sprite _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await game.loadSprite('bg_neon_grid.png');
    // Sized to fit two vertical rooms of 9x16 meters each.
    // Room 1 spans Y: 0 to 16. Room 2 spans Y: -16 to 0.
    size = Vector2(9.0, 32.0);
    position = Vector2(0.0, -16.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Render the grid for Room 2 (Y: -16.0 to 0.0)
    _sprite.render(canvas, position: Vector2(0.0, 0.0), size: Vector2(9.0, 16.0));
    // Render the grid for Room 1 (Y: 0.0 to 16.0)
    _sprite.render(canvas, position: Vector2(0.0, 16.0), size: Vector2(9.0, 16.0));
  }
}
