# Antigravity & Human Pair-Programming Cheat Sheet

Welcome to the development of **Flipoff: Snap**! This cheat sheet outlines our project structure, helper tooling, and communication patterns to make our pair-programming sessions as efficient and collaborative as possible.

---

## 1. Project Directory Layout

*   `lib/` - Flutter source code.
*   `test/` - Unit, widget, and component tests.
*   `.agents/` - Workspace agents customization root:
    *   `skills/` - Custom operational guidelines (skills):
        *   `flame_engine/` - Core Flame Engine skills.
        *   `game_architect/` - Physics, revolute joints, and state machine rules.
        *   `backend_integrations/` - Ads SDKs, shared preferences, and billing.
        *   `ui_ux_designer/` - Viewports, glassmorphic layout, and haptic tokens.
    *   `scripts/` - Automated helper tools (like the verification script).

---

## 2. Helper Tooling & Commands

### A. Run Linting and Codebase Tests:
Before committing or finalizing code, you (or I) can run the test script in PowerShell to verify formatting, lints, and test success:

```powershell
powershell -File .agents/scripts/test_and_lint.ps1
```

### B. Launch Firebase Local Emulator Suite:
To start our local database, authentication, and cloud functions servers for local testing (pre-configured to run with your local JDK 25):

```powershell
# Point to your local JDK 25 (resolves the Java version requirement error):
$env:JAVA_HOME = "C:\Users\peterk\.jdks\jbr-25.0.2"

# Start the emulators (requires no global install):
npx firebase-tools emulators:start
```
*   **Emulator UI Web Dashboard:** `http://localhost:4000` (Visual logs, database viewer, and auth editor)
*   **Firestore Database Port:** `8080`
*   **Firebase Auth Port:** `9099`
*   **Cloud Functions Port:** `5001`

### C. Start Android Phone Emulator:
To launch the pre-configured Android emulator:

```powershell
# List available emulators to find the ID:
flutter emulators

# Launch the Android emulator (e.g., Pixel 9):
flutter emulators --launch Pixel_9
```

---

## 3. Communication Patterns (Getting the Best Out of Antigravity)

### A. Role Invocation (Triggering Specific Skills)
*   **Game Architect:** *"Put on your Game Architect hat and design the physical layout for Chapter 2."*
*   **UI/UX Designer:** *"Put on your UI/UX Designer hat and design the shop transition overlay."*
*   **Backend Developer:** *"Put on your Backend Developer hat and implement the local token storage hooks."*
*   **Graphic Designer:** *"Put on your Graphic Designer hat and generate neon ball sprite variations."*
*   **Project Manager:** *"Put on your Project Manager hat and organize the milestone tasks."*
*   **QA Engineer:** *"Put on your QA Engineer hat and write unit tests for this feature."*



### B. Triggering Slash Commands (Platform Workflows)
You can recommend or run these shortcuts in our chat interface:
*   `/goal`: Use this when you want me to work on a large feature autonomously (e.g., overnight or while you are away). I will plan, write, test, and verify without stopping.
*   `/grill-me`: Use this when you want me to conduct an interactive interview to align on design decisions, table styles, or monetization values before writing code.
*   `/learn`: Use this if we solve a tricky bug or if you correct my behavior, so I can save that rule globally for future turns.

### C. The Pair-Programming Ground Rules
1.  **Simplicity First:** State assumptions out loud. Avoid complex abstractions.
2.  **Goal-Driven:** Break vague requests into testable outcomes (e.g., *"Make sure the double-wide flipper returns to -15 degrees on release"*).
3.  **Surgical Edits:** Only edit the files needed for the active task. No unnecessary refactoring.
4.  **DartDoc Coverage:** All public classes, functions, properties, and parameters must be fully documented using `///` comments to enable IDE rollover tooltips.
5.  **Test Gated:** A feature is not considered complete or ready for code execution until associated unit/widget test scripts are written and pass.

