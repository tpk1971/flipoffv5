# Flipoff: Snap — Master Task Checklist

This document is managed by the **Project Manager** to coordinate tasks across the team.

---

## Milestone 1: Core Physics & Asymmetrical Flipper (Sprint 1)
*   **Testable Goal:** Tap screen $\rightarrow$ Flipper rotates from $-15^\circ$ to $+25^\circ$ $\rightarrow$ Release tap $\rightarrow$ Flipper returns to $-15^\circ$ slope. The ball rolls down, hits the bottom-right sensor, and triggers a table reset.
*   **Artwork Requirements:**
    *   `flipper_neon_purple.png` (80% width glassmorphic bar, purple rim).
    *   `ball_chrome.png` (metallic reflective orb sprite).
*   **Testing Requirements:**
    *   Integration test confirming RevoluteJoint angle limits.
    *   Integration test confirming Gutter sensor detects collisions.
*   **Tasks:**
    - [ ] **[Game Architect]** Initialize Flutter/Flame project structure.
    - [ ] **[Game Architect]** Setup Forge2D world physics (gravity, collision categories).
    - [ ] **[Game Architect]** Implement double-wide flipper with a `RevoluteJoint` and torque impulse.
    - [ ] **[UI/UX Designer]** Implement full-screen touch listener to trigger flipper.
    - [ ] **[Graphic Designer]** Generate `flipper_neon_purple.png` and `ball_chrome.png` assets.
    - [ ] **[QA Engineer]** Write test verifying joint angle limits.
    - [ ] **[QA Engineer]** Write test verifying gutter sensor triggers playfield reset.

---

## Milestone 2: Room Manager & Level Progression (Sprint 2)
*   **Testable Goal:** Load Room 1 from JSON $\rightarrow$ Break 3 targets $\rightarrow$ Exit portal unlocks $\rightarrow$ Enter portal $\rightarrow$ Screen transitions to Room 2.
*   **Artwork Requirements:**
    *   `target_neon_teal.png` (frosted glass indicator, teal glow).
    *   `portal_active.png` (spiral vortex particle sprite).
*   **Testing Requirements:**
    *   Unit test validating JSON parsing.
    *   Integration test confirming room exit loads subsequent layout index.
*   **Tasks:**
    - [ ] **[Game Architect]** Design JSON room geometry configuration schema.
    - [ ] **[Game Architect]** Implement `RoomManager` component to handle active level geometry.
    - [ ] **[UI/UX Designer]** Implement smooth camera Y-coordinate tracking transition when portals load.
    - [ ] **[Graphic Designer]** Generate target and exit portal sprites.
    - [ ] **[QA Engineer]** Write room state progression unit tests.

---

## Milestone 3: UI Theme, Locker Customization & Juice (Sprint 3)
*   **Testable Goal:** Open Locker overlay $\rightarrow$ Select Heavy Steel Ball $\rightarrow$ Ball spawns with $3\times$ mass density. Colliding with bumpers triggers haptics and score popups.
*   **Artwork Requirements:**
    *   `ball_heavy_steel.png` (rusted industrial iron sprite).
    *   `ball_neon_orb.png` (glowing light trail particle package).
*   **Testing Requirements:**
    *   Unit test confirming active `BallConfig` overrides physics properties.
    *   Widget test verifying locker carousel swipe index changes active ball.
*   **Tasks:**
    - [ ] **[UI/UX Designer]** Create Glassmorphic HUD overlay and the swipeable Locker Room panel.
    - [ ] **[Graphic Designer]** Generate `ball_heavy_steel.png` and `ball_neon_orb.png` assets.
    - [ ] **[Game Architect]** Integrate `BallConfig` mappings to Box2D dynamic body densities.
    - [ ] **[UI/UX Designer]** Hook up `HapticFeedback` APIs and score float animations.
    - [ ] **[QA Engineer]** Write tests verifying physics profiles on ball swap.

---

## Milestone 4: Firebase Integration & Token Economy (Sprint 4)
*   **Testable Goal:** Play 3 games $\rightarrow$ Display "Out of Tokens" popup $\rightarrow$ Tap "Watch Ad" or "Use 1 Token" $\rightarrow$ Token count decrements, play credit increments, and state syncs to Firestore.
*   **Artwork Requirements:**
    *   UI asset package for coin tokens and infinite pass badges.
*   **Testing Requirements:**
    *   Unit test validating profile database synchronization.
    *   Widget test confirming click-through paths on Token Gating cards.
*   **Tasks:**
    - [ ] **[Backend Developer]** Set up Firebase Auth (anonymous and linked credentials).
    - [ ] **[Backend Developer]** Deploy Firebase Cloud Functions for Google Play / App Store receipt verification.
    - [ ] **[Backend Developer]** Configure Cloud Firestore collections for user profile ledgers.
    - [ ] **[UI/UX Designer]** Build the "Out of Tokens" continuation card.
    - [ ] **[QA Engineer]** Write tests verifying play limit blocks starting a level without credits.
