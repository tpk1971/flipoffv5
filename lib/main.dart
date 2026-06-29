import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flipoff/game/flipoff_game.dart';

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
  final host = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';
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
      home: const PlayfieldPage(),
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
              child: GameWidget(game: _game),
            ),
          ),
        ),
      ),
    );
  }
}
