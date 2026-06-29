---
name: Flame Engine Development
description: Core patterns, best practices, and architectural principles for developing games with the Flame Engine in Flutter, including FCS, lifecycle, and input handling.
---

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
Modern Flame games (v1.0+) use the `World` and `CameraComponent` pattern.
- **FlameGame Defaults (v1.8.0+)**: `FlameGame` automatically creates a default `world` (an instance of `World`) and `camera` (an instance of `CameraComponent`) that are pre-paired.
- **Viewport & Viewfinder**: The camera viewport defines *where* on the screen the game world renders, while the viewfinder defines *what* coordinates in the world the camera centers/zooms on.
- **Where to Add Components**: 
    - Add game components (players, enemies, maps) to the `world` (e.g., `world.add(player)`) so they are correctly scaled/panned by the camera.
    - Add HUD/UI components (buttons, score overlays) to the camera's viewport or viewfinder to keep them fixed relative to the screen.

```dart
class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Standard FlameGame has a default world and camera, so you can add directly to world
    await world.add(MyPlayerComponent());
  }
}
```

## Input Handling

Input is handled via mixins on individual `Component` classes.

### Taps and Drags
- Use the modern `TapCallbacks` and `DragCallbacks` mixins directly on your components (instead of the legacy `Tappable`/`Draggable` mixins and game-level `HasTappables`/`HasDraggables` properties).
- Override `onTapDown(TapDownEvent event)`, `onTapUp(TapUpEvent event)`, `onDragUpdate(DragUpdateEvent event)`, etc.

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
    // Position inside the game world
    position = Vector2.zero();
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
