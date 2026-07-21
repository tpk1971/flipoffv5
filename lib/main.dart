import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flipoff/game/flipoff_game.dart';
import 'package:flipoff/game/splash_page.dart';
import 'package:flipoff/game/audio_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with mock configuration options suitable for local emulators.
  // This allows local physics sprint prototyping without hard dependency on production credentials.
  const firebaseOptions = FirebaseOptions(
    apiKey: 'mock-api-key-for-emulator-testing',
    appId: '1:1234567890:android:1234567890',
    messagingSenderId: '1234567890',
    projectId: 'flipoff-3799c',
  );

  await Firebase.initializeApp(options: firebaseOptions);

  // Connect Firebase clients to local emulators
  const host = '127.0.0.1';
  try {
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    debugPrint('Successfully connected to Firebase local emulators.');
  } catch (e) {
    debugPrint('Error connecting to Firebase emulators: $e');
  }

  runApp(const MyApp());
}

/// The root Flutter application widget.
class MyApp extends StatelessWidget {
  /// Creates the root application widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flipoff: Snap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D0E15), // Obsidian Dark base
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9D4EDD), // Neon Flipper Purple
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}

/// The main page containing the centered 9:16 ratio playfield container.
class PlayfieldPage extends StatefulWidget {
  /// Creates the main playfield page widget.
  const PlayfieldPage({super.key});

  @override
  State<PlayfieldPage> createState() => _PlayfieldPageState();
}

class _PlayfieldPageState extends State<PlayfieldPage> {
  late final FlipoffGame _game;

  @override
  void initState() {
    super.initState();
    _game = FlipoffGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white24, // Subtle glassmorphic layout boundary
                  width: 2.0,
                ),
              ),
              child: GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'hud': (context, game) => GameHud(game: game as FlipoffGame),
                  'gameOver': (context, game) => GameOverOverlay(game: game as FlipoffGame),
                  'pause': (context, game) => PauseOverlay(game: game as FlipoffGame),
                },
                initialActiveOverlays: const ['hud'],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A HUD overlay displaying the reactive score, current level, and remaining lives.
class GameHud extends StatelessWidget {
  /// The reference to the active game.
  final FlipoffGame game;

  /// Creates a GameHud overlay.
  const GameHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pause button
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.pause, color: Color(0xFFFF007F), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      game.paused = true;
                      GameAudioController.instance.isPaused = true;
                      GameAudioController.instance.pauseMusic();
                      game.overlays.add('pause');
                    },
                  ),
                ),

                // Score readout
                ValueListenableBuilder<int>(
                  valueListenable: game.scoreNotifier,
                  builder: (context, score, _) {
                    return Text(
                      'SCORE: ${score.toString().padLeft(6, '0')}',
                      style: const TextStyle(
                        color: Color(0xFF00F5D4), // Neon Cyan
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Color(0xAA00F5D4),
                            blurRadius: 8.0,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Active Multiball Score Multiplier Badge
                ValueListenableBuilder<int>(
                  valueListenable: game.scoreMultiplierNotifier,
                  builder: (context, multiplier, _) {
                    if (multiplier <= 1) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FFD700),
                            blurRadius: 6.0,
                          ),
                        ],
                      ),
                      child: Text(
                        '${multiplier}x MULTI',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    );
                  },
                ),

                // Lives indicators (balls row)
                ValueListenableBuilder<int>(
                  valueListenable: game.livesNotifier,
                  builder: (context, lives, _) {
                    final displayCount = math.max(3, lives);
                    return Row(
                      children: List.generate(displayCount, (index) {
                        final isActive = index < lives;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFFFF9F1C) // Active Retro Orange
                                : Colors.white24, // Lost/inactive placeholder
                            boxShadow: isActive
                                ? const [
                                    BoxShadow(
                                      color: Color(0xFFFF9F1C),
                                      blurRadius: 4.0,
                                      spreadRadius: 0.5,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An overlay displayed when the player runs out of lives, offering replay or exit.
class GameOverOverlay extends StatelessWidget {
  /// The reference to the active game.
  final FlipoffGame game;

  /// Creates a GameOverOverlay.
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xEE0D0E15), // Obsidian Dark base
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Color(0xFFF25C54), // Warning Red
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: Color(0xAAF25C54),
                          blurRadius: 16.0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your final score has been logged.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<int>(
                    valueListenable: game.scoreNotifier,
                    builder: (context, score, _) {
                      return Text(
                        'SCORE: $score',
                        style: const TextStyle(
                          color: Color(0xFFFFD166), // Gold
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // New Game Button
                  GestureDetector(
                    onTap: game.resetGame,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00F5D4), width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3300F5D4),
                            blurRadius: 8.0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'PLAY AGAIN',
                          style: TextStyle(
                            color: Color(0xFF00F5D4),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Exit to Lobby Button
                  GestureDetector(
                    onTap: () {
                      game.resetGame();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'LOBBY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
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
}

/// An overlay displayed when the player pauses the game, offering mute/unmute and exit buttons.
class PauseOverlay extends StatefulWidget {
  /// The reference to the active game.
  final FlipoffGame game;

  /// Creates a PauseOverlay.
  const PauseOverlay({super.key, required this.game});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  @override
  Widget build(BuildContext context) {
    final audio = GameAudioController.instance;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF007F).withValues(alpha: 0.3),
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33FF007F),
                    blurRadius: 15.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GAME PAUSED',
                    style: TextStyle(
                      color: Color(0xFFFF007F),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: Color(0xAAFF007F),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Music Mute/Unmute
                  _buildMenuButton(
                    text: audio.isMusicMuted ? 'UNMUTE MUSIC' : 'MUTE MUSIC',
                    color: const Color(0xFF00F5D4),
                    onPressed: () async {
                      await audio.toggleMusic();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),

                  // SFX Mute/Unmute
                  _buildMenuButton(
                    text: audio.isSfxMuted ? 'UNMUTE SFX' : 'MUTE SFX',
                    color: const Color(0xFF00F5D4),
                    onPressed: () async {
                      await audio.toggleSfx();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),

                  // Resume Game
                  _buildMenuButton(
                    text: 'RESUME GAME',
                    color: const Color(0xFFFF9F1C),
                    onPressed: () {
                      widget.game.paused = false;
                      GameAudioController.instance.isPaused = false;
                      GameAudioController.instance.resumeMusic();
                      widget.game.overlays.remove('pause');
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quit Game
                  _buildMenuButton(
                    text: 'QUIT GAME',
                    color: const Color(0xFFF25C54),
                    onPressed: () async {
                      widget.game.resetGame();
                      widget.game.paused = false;
                      widget.game.overlays.remove('pause');
                      await audio.stopAll();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
