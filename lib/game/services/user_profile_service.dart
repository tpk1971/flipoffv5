import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flipoff/game/models/user_profile.dart';

/// A service that coordinates local and cloud persistence for the player's profile.
///
/// Integrates [SharedPreferences] for offline caching, [FirebaseAuth] for
/// anonymous user authentication, and [FirebaseFirestore] for wallet syncing.
class UserProfileService {
  UserProfileService._internal();

  /// The singleton instance of [UserProfileService].
  static final UserProfileService instance = UserProfileService._internal();

  /// The cache storage key for SharedPreferences.
  static const String _profileCacheKey = 'cached_user_profile';

  /// A notifier exposing changes to the active [UserProfile] to UI listeners.
  final ValueNotifier<UserProfile> profileNotifier = ValueNotifier<UserProfile>(const UserProfile());

  /// Gets the currently active player profile.
  UserProfile get profile => profileNotifier.value;

  /// Private cache reference for SharedPreferences.
  SharedPreferences? _prefs;

  /// The authenticated user ID (null if not authenticated yet).
  String? _userId;

  /// Gets the authenticated user ID.
  String? get userId => _userId;

  /// Sets the SharedPreferences mock instance (primarily for testing purposes).
  @visibleForTesting
  set mockPrefs(SharedPreferences mock) => _prefs = mock;

  /// Sets the Firebase user ID mock instance (primarily for testing purposes).
  @visibleForTesting
  set mockUserId(String? mockUid) => _userId = mockUid;

  /// Initializes local storage cache and checks for an active authenticated session.
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();

    // 1. Check if a Firebase Auth session is already active
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userId = currentUser.uid;
    }

    // 2. Load the initial cached profile locally
    UserProfile localProfile = _loadLocalCache();

    // 3. Process daily free games reset
    localProfile = _checkDailyReset(localProfile);

    profileNotifier.value = localProfile;

    // 4. If an active session exists, synchronize with Firestore
    if (_userId != null) {
      await _syncWithCloud();
    }
  }

  /// Performs anonymous guest authentication, then triggers Firestore syncing.
  Future<void> loginAnonymously() async {
    try {
      final credentials = await FirebaseAuth.instance.signInAnonymously();
      _userId = credentials.user?.uid;
    } catch (e) {
      debugPrint('UserProfileService: Anonymous Auth failed/offline: $e');
    }

    if (_userId != null) {
      await _syncWithCloud();
    }
  }

  /// Performs mock Google authentication, then triggers Firestore syncing.
  Future<void> loginWithMockGoogle(String googleUid) async {
    _userId = googleUid;
    // In a production setup, this would exchange GoogleSignIn tokens for Firebase credentials:
    // final credentials = await FirebaseAuth.instance.signInWithCredential(credential);
    // _userId = credentials.user?.uid;
    
    await _syncWithCloud();
  }

  /// Loads the cached profile from SharedPreferences.
  UserProfile _loadLocalCache() {
    final cachedString = _prefs?.getString(_profileCacheKey);
    if (cachedString != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(cachedString) as Map<String, dynamic>;
        return UserProfile.fromJson(jsonMap);
      } catch (e) {
        debugPrint('UserProfileService: Error parsing cached profile: $e');
      }
    }
    return const UserProfile();
  }

  /// Synchronously saves the profile to local cache and starts an async Cloud Firestore save.
  Future<void> saveProfile(UserProfile newProfile) async {
    profileNotifier.value = newProfile;

    // Save locally
    try {
      final profileJson = json.encode(newProfile.toJson());
      await _prefs?.setString(_profileCacheKey, profileJson);
    } catch (e) {
      debugPrint('UserProfileService: Error writing to local SharedPreferences: $e');
    }

    // Save to Firestore asynchronously
    if (_userId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .set(newProfile.toJson(), SetOptions(merge: true))
          .catchError((e) {
        debugPrint('UserProfileService: Error writing to Firestore: $e');
        return null;
      });
    }
  }

  /// Syncs local profile with Firestore, resolving any merge conflicts.
  Future<void> _syncWithCloud() async {
    if (_userId == null) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(_userId!);
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data() != null) {
        final remoteProfile = UserProfile.fromJson(docSnap.data()!);
        final mergedProfile = _mergeProfiles(profile, remoteProfile);
        await saveProfile(mergedProfile);
      } else {
        // Document doesn't exist yet, save local profile as initial document
        await docRef.set(profile.toJson());
      }
    } catch (e) {
      debugPrint('UserProfileService: Sync with Firestore failed: $e');
    }
  }

  /// Merges two profiles, resolving conflicts by choosing the highest balances and merging unlock lists.
  UserProfile _mergeProfiles(UserProfile local, UserProfile remote) {
    // Union unlocked chapters
    final chaptersUnion = {...local.unlockedChapters, ...remote.unlockedChapters}.toList();

    // Union unlocked skins
    final skinsUnion = {...local.unlockedSkins, ...remote.unlockedSkins}.toList();

    // Resolve reset date: pick the most recent reset date
    String resolvedResetDate = local.lastResetDate;
    int resolvedFreeGames = local.dailyFreeGames;

    if (remote.lastResetDate.compareTo(local.lastResetDate) > 0) {
      resolvedResetDate = remote.lastResetDate;
      resolvedFreeGames = remote.dailyFreeGames;
    } else if (remote.lastResetDate == local.lastResetDate) {
      // If the dates match, keep the smaller remaining free games count to prevent duplication exploits
      resolvedFreeGames = local.dailyFreeGames < remote.dailyFreeGames ? local.dailyFreeGames : remote.dailyFreeGames;
    }

    return UserProfile(
      dailyFreeGames: resolvedFreeGames,
      tokenCount: local.tokenCount > remote.tokenCount ? local.tokenCount : remote.tokenCount,
      glowDustCount: local.glowDustCount > remote.glowDustCount ? local.glowDustCount : remote.glowDustCount,
      unlockedChapters: chaptersUnion,
      unlockedSkins: skinsUnion,
      activeBallSkin: local.activeBallSkin != 'ball_default' ? local.activeBallSkin : remote.activeBallSkin,
      activeFlipperSkin: local.activeFlipperSkin != 'flipper_default' ? local.activeFlipperSkin : remote.activeFlipperSkin,
      isInfiniteUnlocked: local.isInfiniteUnlocked || remote.isInfiniteUnlocked,
      lastResetDate: resolvedResetDate.isNotEmpty ? resolvedResetDate : local.lastResetDate,
    );
  }

  /// Resets daily free games if midnight has passed.
  UserProfile _checkDailyReset(UserProfile target) {
    final now = DateTime.now();
    final todayString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (target.lastResetDate != todayString) {
      return target.copyWith(
        dailyFreeGames: 3,
        lastResetDate: todayString,
      );
    }
    return target;
  }

  /// Deducts play credits if available. Returns true on success, false if out of credits.
  bool spendPlayCredit() {
    if (profile.isInfiniteUnlocked) {
      return true;
    }
    if (profile.dailyFreeGames > 0) {
      saveProfile(profile.copyWith(dailyFreeGames: profile.dailyFreeGames - 1));
      return true;
    }
    if (profile.tokenCount > 0) {
      saveProfile(profile.copyWith(tokenCount: profile.tokenCount - 1));
      return true;
    }
    return false;
  }

  /// Increments the premium token count by [amount].
  void creditTokens(int amount) {
    saveProfile(profile.copyWith(tokenCount: profile.tokenCount + amount));
  }

  /// Increments the glow dust count by [amount].
  void creditGlowDust(int amount) {
    saveProfile(profile.copyWith(glowDustCount: profile.glowDustCount + amount));
  }
}
