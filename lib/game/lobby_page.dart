import 'package:flutter/material.dart';
import 'package:flipoff/game/services/user_profile_service.dart';
import 'package:flipoff/game/shop_overlay.dart';
import 'package:flipoff/game/locker_page.dart';
import 'package:flipoff/main.dart';

/// The main menu lobby page for Flipoff: Snap.
///
/// Displays high scores, current wallet balances (tokens and glow dust),
/// and options to start the game, customize skins, or visit the shop.
class LobbyPage extends StatelessWidget {
  /// Creates the lobby page widget.
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15), // Obsidian Dark base
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0x33FFFFFF), // Subtle glassmorphic border
                  width: 2.0,
                ),
              ),
              child: ValueListenableBuilder(
                valueListenable: UserProfileService.instance.profileNotifier,
                builder: (context, profile, _) {
                  return Column(
                    children: [
                      // Header Wallet (Tokens & Glow Dust)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Token Balance Card
                          _buildWalletCard(
                            icon: Icons.vpn_key_rounded,
                            iconColor: const Color(0xFF9D4EDD), // Neon Purple
                            label: profile.isInfiniteUnlocked
                                ? 'INFINITE'
                                : 'TOKENS: ${profile.tokenCount} (Free: ${profile.dailyFreeGames})',
                          ),
                          // Glow Dust Balance Card
                          _buildWalletCard(
                            icon: Icons.star_rounded,
                            iconColor: const Color(0xFFFFD166), // Glowing Gold
                            label: 'DUST: ${profile.glowDustCount}',
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Title Logo (Glowing Neon Branding)
                      Text(
                        'FlippOff',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4.0,
                          shadows: [
                            Shadow(
                              blurRadius: 12.0,
                              color: const Color(0xFF9D4EDD).withValues(alpha: 0.85), // Neon Purple
                              offset: Offset.zero,
                            ),
                            Shadow(
                              blurRadius: 24.0,
                              color: const Color(0xFF00F5D4).withValues(alpha: 0.6), // Neon Teal
                              offset: Offset.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'SNAP EDITION',
                        style: TextStyle(
                          color: Color(0xFF00F5D4), // Neon Teal
                          letterSpacing: 6.0,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),

                      // Navigation Options
                      // 1. PLAY BUTTON
                      _buildLobbyButton(
                        context: context,
                        label: 'PLAY GAME',
                        textColor: const Color(0xFF00F5D4), // Neon Teal
                        borderColor: const Color(0xFF00F5D4),
                        onTap: () {
                          final hasCredit = UserProfileService.instance.spendPlayCredit();
                          if (hasCredit) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PlayfieldPage(),
                              ),
                            );
                          } else {
                            // Show shop overlay if credits are depleted
                            showDialog<void>(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) => const ShopOverlay(),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // 2. LOCKER BUTTON
                      _buildLobbyButton(
                        context: context,
                        label: 'CUSTOMIZE SKINS',
                        textColor: Colors.white,
                        borderColor: const Color(0xFF9D4EDD), // Neon Purple
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LockerPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // 3. SHOP BUTTON
                      _buildLobbyButton(
                        context: context,
                        label: 'CREDITS SHOP',
                        textColor: const Color(0xFFFFD166), // Glowing Gold
                        borderColor: const Color(0xFFFFD166),
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            barrierDismissible: true,
                            builder: (_) => const ShopOverlay(),
                          );
                        },
                      ),
                      const Spacer(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a small wallet balance display container.
  Widget _buildWalletCard({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // Glassmorphic card fill
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16.0),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a glowing glassmorphic button for lobby actions.
  Widget _buildLobbyButton({
    required BuildContext context,
    required String label,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06), // ~6% opacity white
          border: Border.all(
            color: borderColor.withValues(alpha: 0.6), // Translucent theme color border
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.15),
              blurRadius: 10.0,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
