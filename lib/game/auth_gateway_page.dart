import 'package:flutter/material.dart';
import 'package:flipoff/game/services/user_profile_service.dart';
import 'package:flipoff/game/lobby_page.dart';

/// The authentication gateway page for new users.
///
/// Prompts the player to authenticate using Google Sign-In, or proceed
/// as a Guest via anonymous credentials.
class AuthGatewayPage extends StatefulWidget {
  /// Creates the authentication gateway page.
  const AuthGatewayPage({super.key});

  @override
  State<AuthGatewayPage> createState() => _AuthGatewayPageState();
}

class _AuthGatewayPageState extends State<AuthGatewayPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate Google Sign-In with a mock credential UID
    await Future.delayed(const Duration(milliseconds: 1200));
    await UserProfileService.instance.loginWithMockGoogle('google_user_mock_123');

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => const LobbyPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  Future<void> _handleGuestPlay() async {
    setState(() {
      _isLoading = true;
    });

    await UserProfileService.instance.loginAnonymously();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => const LobbyPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15), // Obsidian Dark base
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0x33FFFFFF), // Subtle glassmorphic border
                  width: 2.0,
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4)), // Neon Teal
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Title Logo (Glowing Neon Branding)
                        Text(
                          'FlippOff',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4.0,
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
                        const SizedBox(height: 8.0),
                        const Text(
                          'AUTHENTICATION GATEWAY',
                          style: TextStyle(
                            color: Color(0xFF00F5D4),
                            letterSpacing: 3.0,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),

                        const Spacer(),

                        // Glassmorphic Card Container
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Protect your progress, skins, and wallets by signing in now.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24.0),

                              // Google Sign-In Button
                              ElevatedButton.icon(
                                onPressed: _handleGoogleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  elevation: 4.0,
                                ),
                                icon: const Icon(Icons.g_mobiledata_rounded, size: 32.0, color: Color(0xFF4285F4)),
                                label: const Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20.0),

                              // Continue as Guest Link
                              TextButton(
                                onPressed: _handleGuestPlay,
                                child: const Text(
                                  'Continue as Guest',
                                  style: TextStyle(
                                    color: Color(0xFF9D4EDD), // Neon Purple
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.0,
                                    letterSpacing: 1.0,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF9D4EDD),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
