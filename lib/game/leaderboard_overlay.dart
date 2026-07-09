import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flipoff/game/services/user_profile_service.dart';

/// A glassmorphic overlay dialog displaying game leaderboards.
///
/// Supports three tabs: Personal Bests (loaded offline from cache), Daily Top 10,
/// and Global All-Time Top 10 (fetched asynchronously from Cloud Firestore).
class LeaderboardOverlay extends StatefulWidget {
  /// Creates the leaderboard overlay dialog.
  const LeaderboardOverlay({super.key});

  @override
  State<LeaderboardOverlay> createState() => _LeaderboardOverlayState();
}

class _LeaderboardOverlayState extends State<LeaderboardOverlay> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              width: 320,
              height: 480,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.3), // Neon Teal outline
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2200F5D4),
                    blurRadius: 15.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title Header
                  const Text(
                    'LEADERBOARDS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Color(0xFF00F5D4), // Neon Teal
                      shadows: [
                        Shadow(
                          color: Color(0xAA00F5D4),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Tab Bar Controls
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF00F5D4),
                    labelColor: const Color(0xFF00F5D4),
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    tabs: const [
                      Tab(text: 'PERSONAL'),
                      Tab(text: 'DAILY'),
                      Tab(text: 'GLOBAL'),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPersonalTab(),
                        _buildAsyncTab(isDaily: true),
                        _buildAsyncTab(isDaily: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Close Button
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFF00F5D4).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(
                        color: Color(0xFF00F5D4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tab showing personal best scores.
  Widget _buildPersonalTab() {
    final highScores = UserProfileService.instance.profile.highScores;

    if (highScores.isEmpty) {
      return const Center(
        child: Text(
          'No high scores recorded.\nGo set some records!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: highScores.length,
      itemBuilder: (context, index) {
        return _buildScoreRow(index + 1, 'You', highScores[index]);
      },
    );
  }

  /// Tab fetching daily or global high scores asynchronously.
  Widget _buildAsyncTab({required bool isDaily}) {
    final service = UserProfileService.instance;
    final Future<List<Map<String, dynamic>>> loader =
        isDaily ? service.fetchDailyLeaderboard() : service.fetchGlobalLeaderboard();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4)),
            ),
          );
        }

        final scores = snapshot.data ?? [];
        if (scores.isEmpty) {
          return const Center(
            child: Text(
              'No scores recorded yet.\nBe the first to post!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final entry = scores[index];
            final name = entry['displayName'] as String? ?? 'Anonymous';
            final score = entry['score'] as int? ?? 0;
            return _buildScoreRow(index + 1, name, score);
          },
        );
      },
    );
  }

  /// Builds a single list row representing a leaderboard score.
  Widget _buildScoreRow(int rank, String name, int score) {
    Color rankColor = Colors.white54;
    if (rank == 1) rankColor = const Color(0xFFFFD166); // Gold
    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Color(0xFFFF9F1C), // Glowing Orange
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
