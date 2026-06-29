---
name: Game Architect (Pinball)
description: Technical design patterns for Forge2D physics setups, revolute joints, and room state-machine transitions in Flame.
---

# Game Architect: Design & Physics Standards

This document establishes the architectural patterns and physical boundaries for **Flipoff: Snap**.

## 1. Forge2D Physics & Joints

### A. The Double-Wide Flipper
The single, double-wide flipper is pivoted on the left and sweeps upward.
*   **Body Type:** `dynamic`
*   **Fixture Type:** PolygonShape forming the elongated taper of the flipper.
*   **Joint Type:** `RevoluteJoint` anchored to the static left wall.
*   **Joint Limits:** Must be strictly constrained to prevent excessive sweep:
    *   Lower limit (resting slope): -15 degrees (sloping down to the gutter on the right).
    *   Upper limit (maximum sweep): +25 degrees.
*   **Joint Motor:**
    *   `enableMotor` set to `true`.
    *   When the tap gesture occurs, apply high positive torque to swing it upward quickly.
    *   When released, apply a return torque or return spring force to return it to the resting base angle.

### B. World Physics Settings
*   **Gravity:** Lower than standard Box2D to provide casual game pacing:
    ```dart
    Vector2(0, 7.5) // Adjust to balance speed vs reaction window
    ```
*   **Restitution (Bounciness):** Set higher for pop bumpers (`0.85`) and targets (`0.7`) to create satisfying bounce lines, and lower for the flipper rubber (`0.4`) to support cradling.

---

## 2. Level Design & Room Manager

### A. Room Transition Mechanism
*   Each level is a discrete screen/room represented as a `PositionComponent`.
*   Rooms are loaded dynamically from JSON layout templates.
*   When the ball touches the `ExitPortalSensor`, the `RoomManager`:
    1.  Pauses physics updates.
    2.  Removes the current room components.
    3.  Instantiates the next room coordinates.
    4.  Transitions the camera view smoothly to the new bounds.
    5.  Respawns the ball on the flipper base.

### B. Trajectory Prediction Physics
*   Calculate a fast, gravity-based projection path for 20 frames ahead:
    $$\vec{p}(t) = \vec{p}_0 + \vec{v}_0 t + \frac{1}{2} \vec{g} t^2$$
*   Render this prediction as a sequence of small, semi-transparent circle components (`CircleComponent`) that fade out.
