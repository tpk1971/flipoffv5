import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central controller for all background music loop rotation and game sound effects.
///
/// Manages user mute settings (persisted in SharedPreferences) independently
/// for background tracks and triggerable sound effects.
class GameAudioController {
  /// Singleton instance.
  static final GameAudioController instance = GameAudioController._internal();

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
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    isMusicMuted = _prefs.getBool(_musicMuteKey) ?? false;
    isSfxMuted = _prefs.getBool(_sfxMuteKey) ?? false;
    _initialized = true;

    // Pre-cache FlameAudio loop files to minimize load latency during play
    await FlameAudio.audioCache.loadAll([
      'loop_1.wav',
      'loop_2.wav',
      'loop_3.wav',
      'loop_4.wav',
      'loop_5.wav',
      'loop_6.wav',
      'sfx_flipper.wav',
      'sfx_bumper.wav',
      'sfx_target.wav',
      'sfx_gutter.wav',
    ]);
  }

  /// Toggles the background music mute state and saves to cache.
  Future<void> toggleMusic() async {
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
    isSfxMuted = !isSfxMuted;
    await _prefs.setBool(_sfxMuteKey, isSfxMuted);
  }

  /// Rotates background music tracks based on the room index [roomIndex].
  Future<void> playMusicForRoom(int roomIndex) async {
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

  /// Triggers a sound effect by its [name] (e.g. 'sfx_target.wav').
  Future<void> playSfx(String name) async {
    if (!_initialized) await initialize();
    if (isSfxMuted) return;

    await FlameAudio.play(name, volume: 0.8);
  }

  /// Stops all active audio playback (useful on quit).
  Future<void> stopAll() async {
    if (FlameAudio.bgm.isPlaying) {
      await FlameAudio.bgm.stop();
    }
    _currentMusicFile = null;
  }
}
