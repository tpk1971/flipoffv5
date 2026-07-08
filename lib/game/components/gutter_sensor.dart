import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flipoff/game/components/ball.dart';
import 'package:flipoff/game/flipoff_game.dart';

/// A sensor component positioned in the gutter drain opening at the bottom right.
///
/// This component registers contacts with the [Ball] and notifies the [FlipoffGame]
/// to trigger a deferred ball reset, preventing physics state modifications
/// during locked contact solver execution.
class GutterSensor extends BodyComponent<FlipoffGame> with ContactCallbacks {
  /// The vertical offset of the sensor.
  final double yOffset;

  /// Creates the gutter sensor component with optional [yOffset].
  GutterSensor({this.yOffset = 0.0});

  @override
  Body createBody() {
    // Positioned at the center of the drain opening (between x = 6.8 and x = 8.2)
    final def = BodyDef()
      ..userData = this
      ..type = BodyType.static
      ..position = Vector2(7.5, 15.9 + yOffset);

    final body = world.createBody(def);

    // Box dimensions: width is 1.4m (half-width = 0.7m), height is 0.2m (half-height = 0.1m)
    final shape = PolygonShape()..setAsBox(0.7, 0.1, Vector2.zero(), 0.0);

    final fixtureDef = FixtureDef(shape)..isSensor = true;

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is Ball) {
      if (game.ballSaverTimeRemaining > 0.0) {
        // Trigger a medium haptic reset impact
        HapticFeedback.mediumImpact();

        // Request safe shield reset
        game.requestShieldReset();
      } else {
        // Trigger a heavy rumble haptic on gutter drain
        HapticFeedback.heavyImpact();
        game.queueSfx('sfx_gutter.wav');
        game.requestBallReset();
      }
    }
  }
}
