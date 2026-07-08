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
