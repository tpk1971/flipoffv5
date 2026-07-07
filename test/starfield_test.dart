import 'package:flutter_test/flutter_test.dart';
import 'package:flipoff/game/components/starfield.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Starfield Component Tests', () {
    test('Can instantiate Starfield successfully', () {
      final starfield = Starfield();
      expect(starfield, isNotNull);
      expect(starfield.priority, equals(-150));
    });
  });
}
