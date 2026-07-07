import 'dart:async';
import 'package:flutter/material.dart';

/// A manager that simulates preloading and displaying rewarded ads for local testing.
///
/// Features a mock full-screen ad overlay with a 3-second countdown timer.
class MockAdManager {
  /// Displays a full-screen simulated rewarded ad dialog.
  ///
  /// Executes [onAdComplete] once the 3-second countdown ends.
  static void showRewardedAd(
    BuildContext context, {
    required VoidCallback onAdComplete,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFB000000), // High contrast dark backing
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _MockAdOverlay(onAdComplete: onAdComplete);
      },
    );
  }
}

class _MockAdOverlay extends StatefulWidget {
  final VoidCallback onAdComplete;

  const _MockAdOverlay({required this.onAdComplete});

  @override
  State<_MockAdOverlay> createState() => _MockAdOverlayState();
}

class _MockAdOverlayState extends State<_MockAdOverlay> {
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        Navigator.of(context).pop(); // Dismiss ad overlay
        widget.onAdComplete(); // Reward the player
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating Ad Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: const Color(0xFF9D4EDD).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFF9D4EDD)),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Text(
                'SPONSORED ADVERTISEMENT',
                style: TextStyle(
                  color: Color(0xFF9D4EDD), // Neon Purple
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 32.0),

            // Rotating loader circular rings
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5D4)), // Neon Teal
              ),
            ),
            const SizedBox(height: 24.0),

            // Countdown Timer text
            Text(
              'Reward in $_secondsLeft...',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Simulating Rewarded Ad Bridge...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
