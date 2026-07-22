import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central controller for all background music loop rotation and game sound effects.
///
/// Manages user mute settings (persisted in SharedPreferences) independently
/// for background tracks and triggerable sound effects.
class GameAudioController {
  /// Singleton instance.
  static final GameAudioController instance = GameAudioController._internal();

  /// Static flag to completely bypass/disable audio loading and play operations (useful in unit/widget tests).
  static bool enableAudio = true;

  /// Keys for SharedPreferences.
  static const String _musicMuteKey = 'music_muted';
  static const String _sfxMuteKey = 'sfx_muted';

  GameAudioController._internal();

  late final SharedPreferences _prefs;
  bool _initialized = false;

  /// Whether the background music is currently muted.
  bool isMusicMuted = false;

  /// Whether trigger sound effects are currently muted.
  bool isSfxMuted = false;

  /// Currently active loop file name.
  String? _currentMusicFile;

  /// Initializes the audio controller and loads mute preferences from cache.
  Future<void> initialize() async {
    if (!enableAudio) return;
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    isMusicMuted = _prefs.getBool(_musicMuteKey) ?? false;
    isSfxMuted = _prefs.getBool(_sfxMuteKey) ?? false;
    
    // Initialize the Flame BGM audio player
    FlameAudio.bgm.initialize();
    await FlameAudio.bgm.audioPlayer.setReleaseMode(ReleaseMode.loop);
    _initialized = true;
  }

  /// Toggles the background music mute state and saves to cache.
  Future<void> toggleMusic() async {
    if (!enableAudio) return;
    isMusicMuted = !isMusicMuted;
    await _prefs.setBool(_musicMuteKey, isMusicMuted);

    if (isMusicMuted) {
      FlameAudio.bgm.stop();
    } else if (_currentMusicFile != null) {
      // Re-trigger loop if play is unmuted
      await FlameAudio.bgm.play(_currentMusicFile!, volume: 0.5);
    }
  }

  /// Toggles the sound effects mute state and saves to cache.
  Future<void> toggleSfx() async {
    if (!enableAudio) return;
    isSfxMuted = !isSfxMuted;
    await _prefs.setBool(_sfxMuteKey, isSfxMuted);
  }

  /// Rotates background music tracks based on the room index [roomIndex].
  Future<void> playMusicForRoom(int roomIndex) async {
    if (!enableAudio) return;
    if (!_initialized) await initialize();

    // Map 6 loops rotating by roomIndex
    final trackNum = (roomIndex % 6) + 1;
    final file = 'loop_$trackNum.wav';

    if (_currentMusicFile == file) return;
    _currentMusicFile = file;

    if (isMusicMuted) return;

    // Stop current track and trigger the new loop
    if (FlameAudio.bgm.isPlaying) {
      await FlameAudio.bgm.stop();
    }
    await FlameAudio.bgm.play(file, volume: 0.5);
  }

  /// Whether the game is currently paused. Used to suppress new SFX triggers.
  bool isPaused = false;

  /// Triggers a sound effect by its [name] (e.g. 'sfx_target.wav').
  Future<void> playSfx(String name) async {
    if (!enableAudio) return;
    if (!_initialized) await initialize();
    if (isSfxMuted || isPaused) return;

    await FlameAudio.play(name, volume: 0.8);
  }

  /// Stops all active audio playback (useful on quit).
  Future<void> stopAll() async {
    if (!enableAudio) return;
    if (FlameAudio.bgm.isPlaying) {
      await FlameAudio.bgm.stop();
    }
    _currentMusicFile = null;
    isPaused = false;
  }

  /// Pauses the background music.
  void pauseMusic() {
    if (!enableAudio) return;
    if (_initialized && !isMusicMuted) {
      FlameAudio.bgm.pause();
    }
  }

  /// Resumes the background music loop.
  void resumeMusic() {
    if (!enableAudio) return;
    if (_initialized && !isMusicMuted) {
      FlameAudio.bgm.resume();
    }
  }
}
