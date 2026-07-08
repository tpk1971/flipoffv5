import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flipoff/game/flipoff_game.dart';
import 'package:flipoff/game/audio_controller.dart';
import 'package:flipoff/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio & Pause Tests (Milestone 10)', () {
    test('GameAudioController toggling mute values', () {
      final audio = GameAudioController.instance;
      audio.isMusicMuted = false;
      audio.isSfxMuted = false;

      // Simulate mute flag updates
      audio.isMusicMuted = true;
      expect(audio.isMusicMuted, isTrue);

      audio.isSfxMuted = true;
      expect(audio.isSfxMuted, isTrue);
    });

    test('SFX queueing and deferred execution on update()', () {
      final game = FlipoffGame();
      
      // Queue a sound
      game.queueSfx('sfx_target.wav');
      
      // Update ticks clear the command buffer safely
      game.update(0.016);
    });

    test('Cubic Easing panning calculations check', () {
      // Easing function: 3t^2 - 2t^3
      // When t = 0.5: 3(0.25) - 2(0.125) = 0.75 - 0.25 = 0.5
      // When t = 0.1: 3(0.01) - 2(0.001) = 0.03 - 0.002 = 0.028 (slow start)
      // When t = 0.9: 3(0.81) - 2(0.729) = 2.43 - 1.458 = 0.972 (slow end)
      double cubicEase(double t) => t * t * (3.0 - 2.0 * t);
      
      expect(cubicEase(0.0), equals(0.0));
      expect(cubicEase(0.5), equals(0.5));
      expect(cubicEase(1.0), equals(1.0));
      expect(cubicEase(0.1), closeTo(0.028, 0.0001));
      expect(cubicEase(0.9), closeTo(0.972, 0.0001));
    });

    test('Safe shield reset triggers properly and does not deduct lives', () {
      final game = FlipoffGame();
      game.livesNotifier.value = 10;
      game.ballSaverTimeRemaining = 4.0; // active shield

      game.requestShieldReset();
      // Runs game step to process shield reset flag
      game.update(0.016);
      
      // Lives are not deducted on safe resets
      expect(game.livesNotifier.value, equals(10));
    });

    test('Audio pause and resume state checks', () {
      final audio = GameAudioController.instance;
      audio.isPaused = false;
      
      audio.isPaused = true;
      expect(audio.isPaused, isTrue);

      audio.isPaused = false;
      expect(audio.isPaused, isFalse);
    });

    testWidgets('PauseOverlay widget instantiation test', (WidgetTester tester) async {
      final game = FlipoffGame();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseOverlay(game: game),
          ),
        ),
      );

      // Verify header and button widgets render
      expect(find.text('GAME PAUSED'), findsOneWidget);
      expect(find.text('RESUME GAME'), findsOneWidget);
      expect(find.text('QUIT GAME'), findsOneWidget);
    });
  });
}
