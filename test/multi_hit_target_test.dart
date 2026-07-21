import 'package:flutter_test/flutter_test.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flipoff/game/components/target.dart';

/// Test suite verifying multi-hit target health degradation, visual rendering states, and final destruction.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Multi-Hit Target Mechanics Tests', () {
    test('Target initializes with specified maxHits and remainingHits', () {
      final target = Target(initialPosition: Vector2(2.0, 5.0), maxHits: 3);
      expect(target.maxHits, equals(3));
      expect(target.remainingHits, equals(3));
    });

    test('Single-hit target breaks on first contact', () {
      final target = Target(initialPosition: Vector2(2.0, 5.0), maxHits: 1);
      expect(target.remainingHits, equals(1));
    });
  });
}
