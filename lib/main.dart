import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flipoff/game/flipoff_game.dart';
import 'package:flipoff/game/splash_page.dart';

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

                // Lives indicators (balls row)
                ValueListenableBuilder<int>(
                  valueListenable: game.livesNotifier,
                  builder: (context, lives, _) {
                    return Row(
                      children: List.generate(15, (index) {
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
