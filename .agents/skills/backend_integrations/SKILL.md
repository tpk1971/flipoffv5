---
name: Backend & Integrations Developer (Pinball)
description: Implementation standards for local profile state storage, ad bridges, and infinite play billing.
---

# Backend & Integrations: Ads, Billing, and Profiles

This document defines standards for state persistence and external SDK integrations in **Flipoff: Snap**.

## 1. Local State Persistence (`UserProfile`)

*   **Technology:** Flutter `shared_preferences`.
*   **Tracked Attributes:**
    *   `dailyFreeGames`: Max 3 (resets at local midnight).
    *   `tokenCount`: Premium currency balance (1 token = 1 game credit).
    *   `glowDustCount`: Soft currency balance (earned via scoring).
    *   `unlockedChapters`: List of chapter indices.
    *   `unlockedSkins`: List of purchased cosmetic/physics skins.
    *   `activeBallSkin`: Active ball selection.
    *   `activeFlipperSkin`: Active flipper selection.
    *   `isInfiniteUnlocked`: Boolean for premium pass purchase.

### Storage Rules:
*   Never write to local storage synchronously in the game update loop. Cache states in memory and perform asynchronous writes during room loading transitions or game-over states.
*   Serialize skins and levels using JSON maps.

---

## 2. Ad Integration Bridge

*   **Technology:** `google_mobile_ads` SDK.
*   **Implementation Requirements:**
    *   **Preloading:** Initialize the AdMob SDK at app startup. Preload the next rewarded ad in the background while the user is playing:
        ```dart
        RewardedAd.load(adUnitId: myAdUnitId, adRequest: AdRequest(), ...);
        ```
    *   **Fallback Mode:** If the network is unavailable or loading fails, show a clean dialogue warning to the user, allowing them to try again or run a short test gameplay with reduced reward.
    *   **Mock Ads:** For local testing, maintain a `MockAdManager` that plays a simulated 3-second counter screen and triggers the credit success callback.

---

## 3. Premium Pass & Billing Bridges

*   **Technology:** `in_app_purchase` Flutter package linked to a **Firebase Backend**.
*   **SKUs:**
    *   `glow_token_pack_25` ($1.00 AUD)
    *   `glow_token_pack_300` ($10.00 AUD)
    *   `glow_infinite_pass` ($9.99 AUD)
*   **Verification:** Validate transactions server-side using **Firebase Cloud Functions** (bridging directly to Google Play Developer and Apple App Store APIs). This secures purchase states and prevents client-side receipt manipulation.
*   **User Accounts:** Integrate **Firebase Authentication** (utilizing anonymous credentials initially, with upgrade paths to Google/Apple ID) to persist user profiles, token wallets, and high scores across device upgrades.

