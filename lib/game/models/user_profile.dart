import 'package:flutter/foundation.dart';

/// Represents the player's profile data, wallet balances, and unlock progress.
///
/// Encapsulates local and remote state attributes, supporting serialization
/// for SharedPreferences caching and Cloud Firestore syncing.
@immutable
class UserProfile {
  /// The number of daily free games remaining for today.
  final int dailyFreeGames;

  /// The amount of premium tokens owned.
  final int tokenCount;

  /// The amount of glow dust (soft currency) owned.
  final int glowDustCount;

  /// The list of identifiers of chapters unlocked.
  final List<String> unlockedChapters;

  /// The list of identifiers of ball/flipper skins unlocked.
  final List<String> unlockedSkins;

  /// The identifier of the active ball skin.
  final String activeBallSkin;

  /// The identifier of the active flipper skin.
  final String activeFlipperSkin;

  /// Whether the player has purchased the Infinite Play Pass.
  final bool isInfiniteUnlocked;

  /// The date (in YYYY-MM-DD format) when the daily free games were last checked/reset.
  final String lastResetDate;

  /// The player's top 10 scores tracked locally and synced.
  final List<int> highScores;

  /// Creates a [UserProfile] instance.
  const UserProfile({
    this.dailyFreeGames = 3,
    this.tokenCount = 0,
    this.glowDustCount = 0,
    this.unlockedChapters = const ['chapter_1'],
    this.unlockedSkins = const ['ball_default', 'flipper_default'],
    this.activeBallSkin = 'ball_default',
    this.activeFlipperSkin = 'flipper_default',
    this.isInfiniteUnlocked = false,
    this.lastResetDate = '',
    this.highScores = const [],
  });

  /// Instantiates a [UserProfile] from a JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      dailyFreeGames: json['dailyFreeGames'] as int? ?? 3,
      tokenCount: json['tokenCount'] as int? ?? 0,
      glowDustCount: json['glowDustCount'] as int? ?? 0,
      unlockedChapters: (json['unlockedChapters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['chapter_1'],
      unlockedSkins: (json['unlockedSkins'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['ball_default', 'flipper_default'],
      activeBallSkin: json['activeBallSkin'] as String? ?? 'ball_default',
      activeFlipperSkin: json['activeFlipperSkin'] as String? ?? 'flipper_default',
      isInfiniteUnlocked: json['isInfiniteUnlocked'] as bool? ?? false,
      lastResetDate: json['lastResetDate'] as String? ?? '',
      highScores: (json['highScores'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
    );
  }

  /// Converts this [UserProfile] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'dailyFreeGames': dailyFreeGames,
      'tokenCount': tokenCount,
      'glowDustCount': glowDustCount,
      'unlockedChapters': unlockedChapters,
      'unlockedSkins': unlockedSkins,
      'activeBallSkin': activeBallSkin,
      'activeFlipperSkin': activeFlipperSkin,
      'isInfiniteUnlocked': isInfiniteUnlocked,
      'lastResetDate': lastResetDate,
      'highScores': highScores,
    };
  }

  /// Returns a copy of this user profile with the given fields replaced.
  UserProfile copyWith({
    int? dailyFreeGames,
    int? tokenCount,
    int? glowDustCount,
    List<String>? unlockedChapters,
    List<String>? unlockedSkins,
    String? activeBallSkin,
    String? activeFlipperSkin,
    bool? isInfiniteUnlocked,
    String? lastResetDate,
    List<int>? highScores,
  }) {
    return UserProfile(
      dailyFreeGames: dailyFreeGames ?? this.dailyFreeGames,
      tokenCount: tokenCount ?? this.tokenCount,
      glowDustCount: glowDustCount ?? this.glowDustCount,
      unlockedChapters: unlockedChapters ?? this.unlockedChapters,
      unlockedSkins: unlockedSkins ?? this.unlockedSkins,
      activeBallSkin: activeBallSkin ?? this.activeBallSkin,
      activeFlipperSkin: activeFlipperSkin ?? this.activeFlipperSkin,
      isInfiniteUnlocked: isInfiniteUnlocked ?? this.isInfiniteUnlocked,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      highScores: highScores ?? this.highScores,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.dailyFreeGames == dailyFreeGames &&
        other.tokenCount == tokenCount &&
        other.glowDustCount == glowDustCount &&
        listEquals(other.unlockedChapters, unlockedChapters) &&
        listEquals(other.unlockedSkins, unlockedSkins) &&
        other.activeBallSkin == activeBallSkin &&
        other.activeFlipperSkin == activeFlipperSkin &&
        other.isInfiniteUnlocked == isInfiniteUnlocked &&
        other.lastResetDate == lastResetDate &&
        listEquals(other.highScores, highScores);
  }

  @override
  int get hashCode {
    return Object.hash(
      dailyFreeGames,
      tokenCount,
      glowDustCount,
      Object.hashAll(unlockedChapters),
      Object.hashAll(unlockedSkins),
      activeBallSkin,
      activeFlipperSkin,
      isInfiniteUnlocked,
      lastResetDate,
      Object.hashAll(highScores),
    );
  }
}
