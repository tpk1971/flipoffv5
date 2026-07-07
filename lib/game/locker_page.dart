import 'package:flutter/material.dart';
import 'package:flipoff/game/services/user_profile_service.dart';

/// A customization locker page allowing players to select and unlock skins.
///
/// Integrates with the [UserProfileService] to deduct glow dust when unlocking
/// new ball and flipper cosmetics.
class LockerPage extends StatelessWidget {
  /// Creates the locker page widget.
  const LockerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15), // Obsidian Dark base
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Navigation & Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Text(
                            'LOCKER ROOM',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                          // Display Glow Dust balance
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 14.0),
                                const SizedBox(width: 4.0),
                                Text(
                                  '${profile.glowDustCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),

                      // Ball Skins Section
                      const Text(
                        'BALL SKINS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00F5D4), // Neon Teal
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      _buildSkinCarousel(
                        context: context,
                        isBall: true,
                        activeSkin: profile.activeBallSkin,
                        unlockedSkins: profile.unlockedSkins,
                        dustBalance: profile.glowDustCount,
                        items: const [
                          _SkinItem(id: 'ball_default', name: 'Chrome', cost: 0),
                          _SkinItem(id: 'ball_purple', name: 'Neon Purple', cost: 100),
                          _SkinItem(id: 'ball_gold', name: 'Neon Gold', cost: 200),
                        ],
                      ),
                      const SizedBox(height: 32.0),

                      // Flipper Skins Section
                      const Text(
                        'FLIPPER SKINS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9D4EDD), // Neon Purple
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      _buildSkinCarousel(
                        context: context,
                        isBall: false,
                        activeSkin: profile.activeFlipperSkin,
                        unlockedSkins: profile.unlockedSkins,
                        dustBalance: profile.glowDustCount,
                        items: const [
                          _SkinItem(id: 'flipper_default', name: 'Original Purple', cost: 0),
                          _SkinItem(id: 'flipper_teal', name: 'Original Teal', cost: 200),
                          _SkinItem(id: 'flipper_gold', name: 'Original Gold', cost: 300),
                        ],
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

  /// Builds a horizontal carousel item layout for skins.
  Widget _buildSkinCarousel({
    required BuildContext context,
    required bool isBall,
    required String activeSkin,
    required List<String> unlockedSkins,
    required int dustBalance,
    required List<_SkinItem> items,
  }) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isUnlocked = unlockedSkins.contains(item.id);
          final isActive = activeSkin == item.id;

          return GestureDetector(
            onTap: () {
              if (isUnlocked) {
                final currentProfile = UserProfileService.instance.profile;
                UserProfileService.instance.saveProfile(
                  isBall
                      ? currentProfile.copyWith(activeBallSkin: item.id)
                      : currentProfile.copyWith(activeFlipperSkin: item.id),
                );
              }
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 14.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isActive ? 0.08 : 0.04),
                border: Border.all(
                  color: isActive
                      ? (isBall ? const Color(0xFF00F5D4) : const Color(0xFF9D4EDD))
                      : Colors.white.withValues(alpha: 0.12),
                  width: isActive ? 1.8 : 1.0,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.white70,
                    ),
                  ),

                  // Selection State OR Unlock Cost Action
                  if (isActive)
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isBall ? const Color(0xFF00F5D4) : const Color(0xFF9D4EDD),
                      ),
                    )
                  else if (isUnlocked)
                    const Text(
                      'UNLOCKED',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    )
                  else
                    // Unlock action
                    InkWell(
                      onTap: () {
                        if (dustBalance >= item.cost) {
                          final service = UserProfileService.instance;
                          final current = service.profile;
                          final updatedSkins = List<String>.from(current.unlockedSkins)..add(item.id);
                          service.saveProfile(
                            current.copyWith(
                              glowDustCount: current.glowDustCount - item.cost,
                              unlockedSkins: updatedSkins,
                            ),
                          );
                        } else {
                          // Show toast warning of insufficient balance
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Not enough Glow Dust! Play to earn more.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFFFFD166)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFD166), size: 12.0),
                            const SizedBox(width: 4.0),
                            Text(
                              '${item.cost}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD166),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Helper model class holding skin configuration values.
class _SkinItem {
  final String id;
  final String name;
  final int cost;

  const _SkinItem({
    required this.id,
    required this.name,
    required this.cost,
  });
}
