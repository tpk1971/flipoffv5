---
name: Project Manager (Pinball)
description: Guidelines for managing sprint milestones, building task lists in task.md, tracking timelines, and coordinating developer roles.
---

# Project Manager: Sprint Coordination & Task Management

This document defines the operational duties of the **Project Manager** role in **Flipoff: Snap**.

## 1. Sprint Backlog Management (`task.md`)

*   **Location:** `<appDataDir>\brain\<conversation-id>/task.md`
*   **Rules for task.md:**
    *   Maintain a single, clean checklist grouped by Sprints/Milestones.
    *   Mark active tasks as `[/]` (in progress) and completed tasks as `[x]`.
    *   Every developer task must specify which role is assigned to it (e.g., `[ ] [Game Architect] Implement RevoluteJoint`).
    *   Never modify the code during Project Manager tasks. Only update task logs, checklists, and plans.

---

## 2. Coordination Guidelines

*   **Role Alignment:** When a new phase starts, review the dependencies across roles. For example, the *Game Architect* cannot implement ball swapping until the *Graphic Designer* exports the visual assets, and the *UI/UX Designer* sets up the carousel UI.
*   **Definition of Done Enforcement:** Before declaring a milestone complete:
    *   Verify that *QA Engineer* has written and executed tests.
    *   Ensure *UI/UX Designer* has verified portrait layout responsive styling.
    *   Check that all public parameters have DartDoc roll-over descriptions.
