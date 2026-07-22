import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:flipoff/game/audio_controller.dart';
import 'package:flipoff/game/flipoff_game.dart';

void main() {
  // Ensure Flutter binding is initialized for loading assets
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RoomManager should load configurations and transition levels', (WidgetTester tester) async {
    GameAudioController.enableAudio = false;
    final game = FlipoffGame();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(900, 1600)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();

    // Wait for the Flame game engine to be fully loaded and components mounted
    await game.ready();

    // Allow async assets to load and children components to mount
    for (int i = 0; i < 10; i++) {
      game.update(0.016);
      await tester.pump(const Duration(milliseconds: 16));
    }

    // 1. Verify Room 1 (Initial Setup)
    expect(game.roomManager.currentRoomId, equals('room_1'));
    expect(game.roomManager.remainingTargets, equals(3), reason: 'Room 1 starts with 3 targets');
    expect(game.roomManager.activeLayout, isNotNull);
    expect(game.roomManager.activeLayout!.portal.unlocked, isFalse, reason: 'Portal starts locked');

    // 2. Simulate target hit and verify remaining target count decrements
    game.roomManager.onTargetHit();
    expect(game.roomManager.remainingTargets, equals(2));
    expect(game.roomManager.activeLayout!.portal.unlocked, isFalse);

    // Hit the remaining targets to unlock the portal
    game.roomManager.onTargetHit();
    game.roomManager.onTargetHit();
    expect(game.roomManager.remainingTargets, equals(0));
    expect(game.roomManager.activeLayout!.portal.unlocked, isTrue, reason: 'Portal should unlock when targets are cleared');

    // 3. Trigger exit portal entrance and verify room transition sequence
    game.roomManager.onPortalEntered(game.ball);

    // Verify that during Phase 1 (first few frames), camera Y remains at 8.0 (Room 1 center)
    // because snap is de-escalated.
    game.update(0.016);
    await tester.pump(const Duration(milliseconds: 16));
    expect(game.camera.viewfinder.position.y, equals(8.0), reason: 'Camera should not snap to Room 2 instantly during hold');

    // Run the remaining transition updates (150 updates total)
    await tester.runAsync(() async {
      for (int i = 0; i < 149; i++) {
        game.update(0.016);
        await Future.delayed(const Duration(milliseconds: 16));
      }
    });

    // 4. Verify transition to Room 2 was completed
    expect(game.roomManager.currentRoomId, equals('room_2'), reason: 'Should load room_2 after entering portal');
    expect(game.roomManager.remainingTargets, equals(4), reason: 'Room 2 should start with 4 targets');
    expect(game.livesNotifier.value, equals(3), reason: 'Transitioning rooms should not deduct a life');
    expect(game.roomManager.activeLayout!.roomIndex, equals(1), reason: 'Room 2 offset index is 1');
    expect(game.roomManager.activeLayout!.yOffset, equals(-16.0), reason: 'Room 2 offset is -16m');

    // Verify camera target updated
    expect(game.cameraTargetPosition.y, equals(-8.0), reason: 'Camera target Y should center on Room 2');

    // Verify ball repositioned to Room 2 spawn coordinates (spawnPosition is [4.5, 3.0] in JSON)
    // Offset spawn position in Room 2 is (4.5, 3.0 - 16.0) = (4.5, -13.0)
    expect(game.ball.body.position.x, closeTo(4.5, 0.05));
    expect(game.ball.body.position.y, closeTo(-13.0, 0.5));
  });
}
