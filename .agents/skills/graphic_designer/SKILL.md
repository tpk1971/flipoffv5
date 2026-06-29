---
name: Graphic Designer & Visual Artist (Pinball)
description: Guidelines for generating 2D game assets, sprites, background decks, and visual components using AI image generation, aligned with design theme tokens.
---

# Graphic Designer & Visual Artist: Asset Standards

This document outlines standard prompts, styling tokens, and export rules for generating visual assets in **Flipoff: Snap**.

## 1. Visual Style & Palette Consistency

All generated assets must strictly conform to the **Zen Neon Glassmorphic** theme:
*   **Backgrounds:** Deep obsidian darks (`#0D0E15`) with subtle translucent grids or glowing dust particles.
*   **Active Elements:** Pure neon teal (`#00F5D4`) and deep purple/violet (`#9D4EDD`).
*   **High-Value / Premium Items:** Glowing warm gold (`#FFD166`).
*   **Composition:** Clean geometric lines, vector art, smooth gradients, and transparent glass overlays. Avoid messy, cluttered details, human frames, or generic primary colors.

---

## 2. Asset Generation Rules (Prompt Guidelines)

When generating assets using the `generate_image` tool, use the following template structures:

### A. Flipper Skins
*   *Prompt Style:* `"2D clean vector sprite of a pinball flipper. Minimalist shape, glowing neon purple edge, transparent glassmorphic center. High-fidelity game asset, pure dark background, isolated."`

### B. Ball Skins
*   *Prompt Style:* `"Isolated game asset sprite of a pinball marble. Polished chrome metal, reflecting neon teal light, or a glowing glass orb with particle trails. Isolated on pure black background, 2D sprite."`

### C. Background Decks / Playfields
*   *Prompt Style:* `"Minimalist mobile game vertical playfield layout. Dark obsidian base, geometric neon purple boundaries, clean vector lanes, glowing teal pop bumpers. High contrast, dark mode, vertical 9:16 layout, no phone frame."`

---

## 3. Flutter Export & Organization

1.  **Image Optimization:** Save generated files into the Flutter assets directory under:
    `assets/images/`
2.  **Asset Naming:** Use clear snake_case descriptions:
    *   `ball_chrome.png`
    *   `flipper_neon_purple.png`
    *   `bg_neon_grid.png`
3.  **Config Mapping:** Update `pubspec.yaml` assets section to register the newly created files.
