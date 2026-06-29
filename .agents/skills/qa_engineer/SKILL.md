---
name: QA Engineer (Pinball)
description: Testing standards for Flame/Forge2D games, including unit tests, widget tests, and automated build verification scripts.
---

# QA Engineer & SDET: Testing Standards

This document establishes the testing guidelines and quality check criteria for **Flipoff: Snap**.

## 1. Automated Testing Frameworks

All test scripts must reside inside the `test/` directory.

### A. Unit Tests
*   Used for testing state management, mathematical utilities, and configuration parsing.
*   *Key Target:* Test `UserProfile` load/save cycles, token increments, and unlocked chapter mappings.

### B. Widget Tests
*   Used for testing Flutter overlays (menus, shop carousels, continue screens).
*   *Key Target:* Verify that tapping the "Watch Ad" button on the Out of Tokens popup fires the Google Mobile Ads listener callback.

### C. Flame Game/Component Tests (Integration)
*   Utilize `flame_test` package to simulate game loops.
*   *Key Target:* Verify that the ball triggers the gutter sensor, and check that revolute joint angles clamp within the -15 to +25 degree limits under high impulse torque.

---

## 2. Test Verification Workflow

Before submitting a milestone:
1.  Run the verification script:
    `powershell -File .agents/scripts/test_and_lint.ps1`
2.  If any check fails (lint or test), the code is not considered "Done." You must debug and fix the errors before declaring victory.
3.  Write descriptive test titles using the pattern: `[Feature] should [Expected Behavior] when [Trigger Condition]`.
