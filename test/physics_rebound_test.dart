import 'package:flutter_test/flutter_test.dart';
import 'package:flipoff/game/components/room_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Physics Rebound & Flipper Relocation Tests (Milestone 9)', () {
    test('Flipper pivot vertical position check', () {
      final config = {
        'gridColor': '#00FF00',
        'bumperColor': '#00FF00',
        'flipperColor': '#00FF00',
        'targetColor': '#00FF00',
        'bumpers': [],
        'targets': [],
      };
      
      final layout = RoomLayout(roomIndex: 0, config: config);
      expect(layout.flipper.initialPosition.y, equals(13.0));
      
      final layoutRoom2 = RoomLayout(roomIndex: 1, config: config);
      expect(layoutRoom2.flipper.initialPosition.y, equals(-3.0)); // 13.0 - 16.0
    });
  });
}
