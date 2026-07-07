import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flipoff/game/services/user_profile_service.dart';
import 'package:flipoff/game/lobby_page.dart';
import 'package:flipoff/game/auth_gateway_page.dart';

/// A custom, premium splash screen for FlippOff.
///
/// Renders the Candidate 2 glassmorphic flipper background asset with
/// a glowing neon "FlippOff" text logo, fading in and out smoothly
/// before transitioning to the game's main playfield.
class SplashPage extends StatefulWidget {
  /// Creates the custom splash page widget.
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// The current opacity value for the fade animation.
  double _opacity = 0.0;

  /// Future representing the background service initialization progress.
  late final Future<void> _initFuture;

  /// Timer for showing the loading status if initialization takes longer than 1.5 seconds.
  Timer? _loadingTimer;

  /// Whether to display a loading status indicator.
  bool _showLoadingText = false;

  @override
  void initState() {
    super.initState();

    // Start loading user profile and checking session
    _initFuture = UserProfileService.instance.initialize();

    // Trigger the fade-in animation shortly after first frame layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // If initialization takes longer than 1.5s, display status message
    _loadingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _opacity > 0.0) {
        setState(() {
          _showLoadingText = true;
        });
      }
    });

    _startTransitionSequence();
  }

  /// Coordinates minimum splash display time and service loading before transitioning.
  void _startTransitionSequence() async {
    // Keep the splash screen open for a minimum of 2200ms for visual branding
    await Future.delayed(const Duration(milliseconds: 2200));

    // Wait for the user profile service initialization to complete
    try {
      await _initFuture;
    } catch (e) {
      debugPrint('SplashPage: Initialization error: $e');
    }

    _loadingTimer?.cancel();

    if (mounted) {
      setState(() {
        _opacity = 0.0;
      });
    }

    // Wait for the fade-out animation to finish, then navigate to lobby or gateway
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      final currentUser = FirebaseAuth.instance.currentUser;
      final targetPage = currentUser != null ? const LobbyPage() : const AuthGatewayPage();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => targetPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15), // Obsidian Dark base
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display the Candidate 2 splash illustration in 9:16 aspect ratio
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Image.asset(
                            'assets/images/splash.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                // Glowing modern FlippOff text branding
                Text(
                  'FlippOff',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3.0,
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
                const SizedBox(height: 12.0),
                // Display subtle status message if initialization is slow
                AnimatedOpacity(
                  opacity: _showLoadingText ? 0.7 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Text(
                    'Establishing secure link...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9D4EDD), // Neon Purple
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 36.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
