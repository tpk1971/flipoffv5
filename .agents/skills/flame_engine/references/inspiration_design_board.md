# Visual Inspiration Design Board: Flipoff (Snap Edition)

To make *Flipoff: Snap* stand out, our design must capture the raw, mechanical, high-energy appeal of physical pinball subculture and blend it with a clean, modern, mobile-first aesthetic. This document serves as a persistent visual guide for all future tables, assets, and UI components.

---

## 1. The Pinball Subculture & Design Vibe

Physical pinball has a rich design history, and modern pinball enthusiasts are drawn to specific visual subcultures:

### A. Mechanical Transparency ("Cyber-Hardware")
*   **The Vibe:** The appeal of seeing the inner workings of the machine.
*   **Design Rule:** Tables should feature "exposed" glowing circuit paths underneath translucent glass playfields, resembling the trace lines of a motherboard. Flipper assemblies should look structural and industrial, not just flat color shapes.

### B. Retro-Futurism & Synthwave
*   **The Vibe:** The high-contrast, laser-glowing arcade nostalgia of the 1980s.
*   **Design Rule:** High-contrast color pairings—primarily deep obsidian grids, electric cyans, magenta/purples, and hot gold. Gridlines and light vectors should guide the player's eyes toward active lanes.

### C. Tactile Sensory Synesthesia (Audio-Visual Link)
*   **The Vibe:** In physical pinball, every sound is mechanical (solenoids thumping, metal clicking, glass ringing) and paired with flashing incandescent bulbs.
*   **Design Rule:** Every collision must trigger a simultaneous audio note, camera shake, and particle burst. Visual effects should pulse to the beat of the ambient soundtrack.

---

## 2. The Visual Inspiration Mood Board

This collage represents the collision of retro arcade hardware, glowing glassmorphic geometry, and modern dark-mode layouts:

![Visual Mood Board Collage](file:///C:/Users/peterk/.gemini/antigravity-ide/brain/8c719297-fba6-43b9-95eb-68391555597d/pinball_mood_board_1782697079938.png)

---

## 3. Style Sheets & Design System Tokens

### A. Palette Specification

| Token | Hex Value | Role in Game UI / Table |
| :--- | :--- | :--- |
| **Obsidian Base** | `#0D0E15` | Playfield floor, dark mode card backs, and UI backing. |
| **Grid Slate** | `#1C1E2A` | Background gridlines, dividing borders, inactive lanes. |
| **Laser Purple** | `#9D4EDD` | The active Single Flipper, lanes feed indicators, and key ramps. |
| **Electric Teal** | `#00F5D4` | Pop bumpers, score indicators, and primary light arrows (flow indicators). |
| **Cyber Gold** | `#FFD166` | Target switches, premium tokens, and Infinite unlocked highlights. |
| **Drain Red** | `#F25C54` | The gutter zone, warnings, and low-energy popups. |

### B. Typography Hierarchy
*   **DMD Font (Digital Font):** Used for large score displays, "+Score" popups, and multiplier cards. Relies on dot-matrix style fonts (e.g. *Press Start 2P* or customized pixel fonts) to reference classic DMD panels.
*   **Geometric Sans-Serif:** Used for standard UI headers, locker labels, and settings. Relies on clean, modern typefaces (e.g., *Orbitron* or *Outfit*).

### C. Materials & Shaders
*   **Glassmorphism:** Buttons, popups, and bumpers must use frosted glass shaders:
    *   *Opacity:* `0.05` to `0.08` fill, `0.15` border.
    *   *Blur:* Sigma $X=10, Y=10$.
*   **Chrome Finish:** Balls must feature a mirror reflection shader that reflects the neon purple and teal playfield lighting to convey physical depth.

---

## 4. AI Image Generation Prompt Recipes

To maintain visual consistency across all future assets, use these exact prompt templates:

*   **New Chapters/Tables Prompt:**
    > *"Minimalist 2D vertical pinball table layout, aspect ratio 9:16. Dark obsidian background with faint glowing circuit lines, neon [Teal/Purple/Orange] geometric lanes, glassmorphic pop bumpers, clean vector design, high contrast game art, no device frame."*
*   **Custom Flipper Skins Prompt:**
    > *"2D sprite sheet asset of a pinball flipper. Transparent glass center with mechanical steel gears at the pivot point, glowing neon [Color] rim. Isolated on pure black background, vector style."*
*   **Custom Ball Skins Prompt:**
    > *"Isolated 2D game asset sprite of a pinball marble. [Material: e.g. red plasma, molten gold, frosted ice] sphere, reflecting high-contrast neon lights. 2D vector style, isolated on black."*
