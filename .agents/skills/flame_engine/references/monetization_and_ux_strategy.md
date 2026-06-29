# Monetization & UX Design Strategy: Flipoff (Snap Edition)

Optimizing engagement and monetization for a micro-session game (5–10 minutes) requires balancing **business revenue** with **player good-will**. If a monetization model is too aggressive, casual players uninstall; if it is too soft, the game cannot sustain development.

This document details the market research, monetization loops, user journeys, and visual layouts for **Flipoff: Snap**.

---

## 1. Market Research & Player Psychology

To design our model, we analyzed user reviews of similar physics and pinball titles (*Zen Pinball*, *Pinball FX*, *Holedown*, *Pocket Run Pool*):

### Key Insights from Player Reviews:
*   **"Pay-to-Play" Energy Hatred:** Players despise strict "energy walls" where they are locked out of the game and *must* pay to continue. However, they are highly tolerant of **optional rewarded video ads** to gain playtime.
*   **The "Premium Escape" Demand:** A vocal segment of gamers wants to buy a "Premium Pass" or a one-time purchase to remove all ads and limitations forever. Offering this increases review ratings on the App Store.
*   **Value of Cosmetic Over Power Upgrades:** Players prefer spending money on cool skins (custom chrome balls, neon trials, unique flippers) or table expansions rather than pay-to-win items.

---

## 2. The Proposed Monetization Engine

We propose a hybrid economy of **Gated Play (Tokens/Ads)** and **Horizontal Customization (Upgrades/Skins)**.

```
                  MONETIZATION FLOW
                  
                 [ Start Daily Session ]
                            |
                 ( 3 Free Daily Games )
                            |
                    [ Games Depleted? ]
                            |
         +------------------+------------------+
         |                                     |
    [ Watch Ad ]                       [ Spend Token ]
    (30s Rewarded Video)                (1 Token = 1 Game)
         |                                     |
   [ +1 Free Game ]                     [ Play Instantly ]
         |                                     |
         +------------------+------------------+
                            |
                      [ Play Table ]
                            |
                 ( Earns "Glow Dust" )
                            |
         +------------------+------------------+
         |                                     |
   [ Unlock Skins ]                     [ Unlock Tables ]
   (Soft Currency/Achievements)         (Earn Stars or Buy early)
```

### A. The Game Credit Economy
*   **Daily Allowance:** The user gets **3 Free Game Credits** every day. A credit is consumed when entering a table/room.
*   **The Token (Premium Currency):**
    *   **$1.00 AUD = 25 Tokens** (4¢ AUD per game credit).
    *   Tapping "Start" spends 1 Token to enter a level.
*   **Rewarded Ads:** Watching a 30-second video ad gives **1 Free Game Credit**. This accommodates purely F2P players.
*   **Bulk Coin Packs & The "Infinite Pass":**
    *   *Starter Pack:* 25 Tokens for $1.00 AUD.
    *   *Arcade Pack:* 300 Tokens for $10.00 AUD (Save 16%).
    *   *Go Infinite Pass:* **$9.99 AUD (One-Time Purchase).** Removes all daily gates, disables ads, and grants unlimited access to all current and future chapters.

### B. Horizontal Progression (Locker Customization)
Instead of linear stat-boosting upgrades that make the game easy, items provide different **physics characteristics** or visual styles (horizontal upgrades):
*   **Ball Skins:**
    *   *Chrome Ball (Standard):* Default weight and slide.
    *   *Heavy Steel Ball (High mass, low bounce):* Clears heavy blocks easily but drops faster. Unlocked via Achievements.
    *   *Neon Orb (Low mass, high trail):* Floats longer, providing more time to align shots.
*   **Flipper Shapes/Skins:**
    *   Sleek glassmorphic, retro wood, or plasma neon.
    *   Purchased using **Glow Dust** (soft currency earned via points/scoring in-game) or unlocked by clearing chapters.

---

## 3. User Journey Maps

### Journey A: The Casual F2P Player ("The Commuter")
*   **Persona:** Plays for 5 minutes during a morning bus ride.
*   **Steps:**
    1. Opens the app, claims 3 daily free games, and plays Room 1, 2, and 3.
    2. Depletes free credits. Prompted with the "Out of Tokens" screen.
    3. Chooses "Watch Ad" to unlock Room 4. Watches a 30-second ad.
    4. Finishes Room 4, closes app.
*   **Revenue Impact:** High ad impressions (eCPM), high retention, but no direct IAP spending.

### Journey B: The Active Enhancer ("The Token Collector")
*   **Persona:** Loves customization; plays for 10 minutes a day and wants to unlock skins quickly.
*   **Steps:**
    1. Runs out of daily credits. Wants to continue playing a tough level immediately.
    2. Purchases the $1.00 AUD Starter Pack (25 Tokens).
    3. Spends 2 Tokens, clears Room 5, and earns enough **Glow Dust** to unlock the *Neon Orb* ball skin.
    4. Enters the Locker Room, equips the Neon Orb, and spends another Token to try Room 6.
*   **Revenue Impact:** Direct low-value microtransactions. Highly repeatable.

### Journey C: The Dedicated Purist ("The Premium Gamer")
*   **Persona:** Hates ads and microtransactions, but loves high-quality mobile games.
*   **Steps:**
    1. Opens the game for the first time. Plays 3 games.
    2. Encounters the "Out of Tokens" screen.
    3. Notices the **"Go Infinite ($9.99 AUD)"** option.
    4. Purchases "Go Infinite" immediately to play at their own pace.
*   **Revenue Impact:** High upfront IAP payout ($9.99 AUD), converts user into a brand advocate who leaves positive reviews.

---

## 4. Visual Mockups

We have generated two core screens to represent this monetization and progression loop.

### Screen 1: The Pre-Game Locker Room
This screen allows players to customize their items and spend their game credits.

![Locker Customization Screen](file:///C:/Users/peterk/.gemini/antigravity-ide/brain/8c719297-fba6-43b9-95eb-68391555597d/customization_locker_mockup_1782695752014.png)

*   **Customization Carousel:** Swipe left/right on the ball and flipper slots to substitute active elements.
*   **Currency Trackers:** Display active **Tokens** and **Glow Dust** in the upper bar.
*   **The Play Call-to-Action:** The button clearly shows that starting the level costs "1 Token."

### Screen 2: The continuation/Ad Wall
This pop-up card appears immediately when a player depletes their daily free credits.

![Out of Tokens Screen](file:///C:/Users/peterk/.gemini/antigravity-ide/brain/8c719297-fba6-43b9-95eb-68391555597d/out_of_tokens_continue_mockup_1782695763859.png)

*   **Clear Value Options:** Gives three distinct, un-cluttered options:
    1.  *Watch Ad (+1 Game):* Time-cost only.
    2.  *Use 1 Token:* Fast, premium credit.
    3.  *Go Infinite ($9.99 AUD):* The ultimate premium option.

---

## 5. Technical Implementation Blueprint

To deploy this in the Flame Engine, we will use Flutter's platform integration layer:

1.  **State Management (Credits and Shop):**
    *   Maintain a local game profile (tokens count, soft currency, unlocked skins) using `shared_preferences` for local caching.
    *   Sync profile data with a backend database (e.g. Firebase Firestore) if the player logs in.
2.  **Ad Integration:**
    *   Integrate the `google_mobile_ads` Flutter package.
    *   Preload **Rewarded Video Ads** in the background so there is zero buffering latency when the player presses "Watch Ad."
3.  **Flipper and Ball Physics Swapping:**
    *   Store physical properties in a local `BallConfig` object:
        ```dart
        class BallConfig {
          final String name;
          final double mass;
          final double restitution;
          final String spriteAsset;
          
          BallConfig({required this.name, required this.mass, required this.restitution, required this.spriteAsset});
        }
        ```
    *   Pass the active `BallConfig` to the Forge2D body generator when spawning the ball into a room.
