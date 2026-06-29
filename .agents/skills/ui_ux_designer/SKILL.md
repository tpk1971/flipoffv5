---
name: UI/UX Designer & Engineer (Pinball)
description: Design system rules for portrait layouts, neon glassmorphic aesthetics, carousels, and haptic feedback.
---

# UI/UX Designer & Engineer: Layout & Theme Standards

This document establishes layout, sensory feedback, and aesthetic system tokens for **Flipoff: Snap**.

## 1. Visual Theme System (Neon Glassmorphic)

Our design system utilizes a dark neon color palette with glassmorphism styling to create a premium, calm, and high-contrast look.

### Color Palette (Hex Codes)
*   **Base Backdrop:** `#0D0E15` (Obsidian Dark)
*   **Active Neon Purple:** `#9D4EDD` (Flipper / Primary Rails)
*   **Active Neon Teal:** `#240046` / `#00F5D4` (Bumpers / Orbits)
*   **Active Neon Gold:** `#FFD166` (Premium Items / Infinite)
*   **Gutter/Drain Warning:** `#F25C54` (Warning Red)

### Glassmorphism Card Properties:
*   **Fill Color:** `#FFFFFF` with `0.05` to `0.08` opacity.
*   **Border Color:** `#FFFFFF` with `0.15` opacity.
*   **Backdrop Filter:** Blur filter with sigma $X=10, Y=10$:
    ```dart
    BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(...),
    )
    ```

---

## 2. Portrait Viewport Layout & Safe Areas

*   **Aspect Ratio Constraint:** Lock the playfield container ratio to exactly `9:16`.
*   **Margins:** On wider mobile devices (or web builds), center-align the playfield and apply dark blur borders on the side margins.
*   **HUD Placement:** Place chapter information and targets count in the upper safe zone (`SafeArea`). Place coins/tokens balances at the top-right corner.
*   **Customization Carousel:** Structure the Locker carousel at the bottom of the screen with a clean horizontal gesture swipe.

---

## 3. Sensory Feedback (Juice)

### A. Haptic Patterns
*   **Bumpers Collision:** Light haptic impact (`HapticFeedback.lightImpact()`).
*   **Outlane Drain:** Heavy rumble pattern (`HapticFeedback.heavyImpact()`).
*   **Flipper Action Limit:** Short click vibration (`HapticFeedback.selectionClick()`).

### B. Particles & Score Spawns
*   Upon target hit, spawn a transient `ScorePopupComponent` displaying `+Score` that floats up $30\text{px}$ and fades out over $600\text{ms}$.
*   Render neon particle sparks on flipper hits using a radial burst particle generator.
