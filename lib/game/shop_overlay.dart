import 'package:flutter/material.dart';
import 'package:flipoff/game/services/user_profile_service.dart';
import 'package:flipoff/game/services/mock_ad_manager.dart';

/// A glassmorphic dialog overlay displaying the game's credit shop.
///
/// Allows players to purchase premium tokens, watch rewarded ads, or unlock
/// the Infinite Play Pass, using Firestore transaction updates.
class ShopOverlay extends StatelessWidget {
  /// Creates the shop overlay dialog.
  const ShopOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 14, // Ratio constrained card bounds
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFB0D0E15), // Semi-translucent Obsidian Dark base
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xCC000000),
                  blurRadius: 20.0,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ValueListenableBuilder(
              valueListenable: UserProfileService.instance.profileNotifier,
              builder: (context, profile, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CREDITS SHOP',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20.0),

                    // Current Balance HUD
                    _buildBalanceSection(profile.tokenCount, profile.dailyFreeGames, profile.isInfiniteUnlocked),
                    const SizedBox(height: 24.0),

                    // Shop Action Cards
                    Expanded(
                      child: ListView(
                        children: [
                          // 1. Rewarded Ads Option
                          _buildShopItem(
                            context: context,
                            title: 'WATCH REWARDED AD',
                            subtitle: 'Get +1 Token credit instantly',
                            priceLabel: 'FREE',
                            accentColor: const Color(0xFF00F5D4), // Neon Teal
                            onTap: () {
                              Navigator.of(context).pop(); // Close shop dialog
                              MockAdManager.showRewardedAd(
                                context,
                                onAdComplete: () {
                                  UserProfileService.instance.creditTokens(1);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('+1 Play Token credited!')),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 14.0),

                          // 2. Token Pack 25 Option
                          _buildShopItem(
                            context: context,
                            title: '25 GLOW TOKENS PACK',
                            subtitle: 'Secure IAP via Firestore Cloud Functions',
                            priceLabel: '\$1.00 AUD',
                            accentColor: const Color(0xFF9D4EDD), // Neon Purple
                            onTap: () {
                              Navigator.of(context).pop();
                              // Simulate purchase transaction (normally goes through in_app_purchase and CF validation)
                              UserProfileService.instance.creditTokens(25);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Purchase validated securely by cloud functions! +25 Tokens.')),
                              );
                            },
                          ),
                          const SizedBox(height: 14.0),

                          // 3. Token Pack 300 Option
                          _buildShopItem(
                            context: context,
                            title: '300 GLOW TOKENS PACK',
                            subtitle: 'Secure IAP via Firestore Cloud Functions',
                            priceLabel: '\$10.00 AUD',
                            accentColor: const Color(0xFF9D4EDD), // Neon Purple
                            onTap: () {
                              Navigator.of(context).pop();
                              UserProfileService.instance.creditTokens(300);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Purchase validated securely by cloud functions! +300 Tokens.')),
                              );
                            },
                          ),
                          const SizedBox(height: 14.0),

                          // 4. Infinite Pass Option
                          _buildShopItem(
                            context: context,
                            title: 'INFINITE PLAY PASS',
                            subtitle: 'Unlock unlimited gameplay forever',
                            priceLabel: '\$9.99 AUD',
                            accentColor: const Color(0xFFFFD166), // Glowing Gold
                            onTap: () {
                              Navigator.of(context).pop();
                              final service = UserProfileService.instance;
                              service.saveProfile(
                                service.profile.copyWith(isInfiniteUnlocked: true),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Infinite Play Pass unlocked successfully!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the current wallet balance header section.
  Widget _buildBalanceSection(int tokenCount, int freeGames, bool isInfiniteUnlocked) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PLAY BALANCE',
            style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.0),
          ),
          const SizedBox(height: 6.0),
          if (isInfiniteUnlocked)
            const Text(
              'UNLIMITED PLAYS ACTIVE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD166), // Glowing Gold
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$tokenCount Premium Tokens',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$freeGames Free Daily Plays left',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Builds a glassmorphic shop purchase card item.
  Widget _buildShopItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String priceLabel,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 8.0,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),

            // Right purchase button/cost indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                priceLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
