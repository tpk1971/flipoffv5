# Flame Engine Development Skills

This document outlines the core patterns, best practices, and architectural principles for developing games with the Flame Engine in Flutter.

## Core Architecture: Flame Component System (FCS)

Flame uses a component-based architecture similar to Flutter's widget tree. Every game object is a `Component`.

### 1. FlameGame
The `FlameGame` class is the backbone of your game. It manages the component tree, lifecycle, and integration with Flutter.

- **Initialization**: Always override `onLoad` for asynchronous setup (loading assets, adding initial components).
- **Game Loop**:
    - `update(double dt)`: Handle game logic. `dt` is the delta time since the last update.
    - `render(Canvas canvas)`: Custom drawing logic (rarely needed if using standard components).
- **GameWidget**: Use `GameWidget(game: myGame)` to embed your game into the Flutter UI.

### 2. Component Lifecycle
Understanding the lifecycle is critical for resource management and performance.

| Method | Description |
| :--- | :--- |
| `onLoad` | Asynchronous initialization. Runs once. Use for `await` operations. |
| `onMount` | Called when the component is added to a mounted parent. Can run multiple times if re-added. |
| `update` | Runs logic every frame. |
| `render` | Draws the component every frame. |
| `onRemove` | Cleanup logic. Runs when removed from the tree. |
| `onGameResize` | Called whenever the game window/screen size changes. |

### 3. PositionComponent
The base class for most game objects. It provides:
- `position`: `Vector2` (x, y).
- `size`: `Vector2` (width, height).
- `angle`: Rotation in radians.
- `anchor`: The logical "center" or origin of the component (e.g., `Anchor.center`).
- `priority`: Sorting order (z-index). Higher values render on top.

### 4. World and Camera
Modern Flame games (v1.0+) should use the `World` and `CameraComponent` pattern.

- **World**: A container for all non-UI game components.
- **Camera**: Defines how the world is viewed (zoom, follow, viewports).
- **HUD**: Add UI elements directly to the `FlameGame` (or as children of the camera's viewport) so they stay static while the camera moves.

```dart
class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    final world = MyWorld();
    final camera = CameraComponent(world: world);
    addAll([world, camera]);
  }
}
```

## Input Handling

Input is handled via mixins on your `FlameGame` or individual `Component` classes.

### Taps and Drags
- Add `HasTappables` (deprecated) -> Use `TapCallbacks` and `DragCallbacks` mixins.
- Override `onTapDown`, `onTapUp`, `onDragUpdate`, etc.

### Keyboard
- Mixin `KeyboardEvents` on your `FlameGame`.
- Override `onKeyEvent`.

## Best Practices

1.  **Prefer `onLoad` over Constructors**: Use `onLoad` for any logic that depends on the game instance or requires `await`.
2.  **Use `Vector2`**: Always use Flame's `Vector2` for coordinates and sizes. Avoid `Offset` or `Size` from Flutter unless necessary for interop.
3.  **Component Composition**: Instead of deep inheritance, compose components by adding them as children.
4.  **Asset Management**: Use `images.load()` or `spritesheet.load()` within `onLoad`. Flame caches these automatically.
5.  **Priority Management**: Use the `priority` property for layering instead of relying on addition order.
6.  **Avoid Global State**: Use `HasGameRef<MyGame>` mixin to access the game instance from components.
7.  **Parallax**: Use `ParallaxComponent` for scrolling backgrounds.

## Example: Simple Player Component

```dart
class Player extends SpriteComponent with HasGameRef<MyGame>, TapCallbacks {
  Player() : super(size: Vector2.all(64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('player.png');
    position = gameRef.size / 2;
  }

  @override
  void update(double dt) {
    // Simple movement
    position.x += 100 * dt; 
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Handle jump or action
  }
}
```
