import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flipoff/sprites/flipper_sprite.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(540, 960),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setResizable(false);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final myGame = MyGame();
    return GameWidget(game: myGame);
  }
}

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set to 9:16 portrait aspect ratio
    camera.viewport = FixedAspectRatioViewport(aspectRatio: 9 / 16);
    // Use a consistent virtual coordinate system (1080x1920)
    camera.viewfinder.visibleGameSize = Vector2(1080, 1920);
    camera.viewfinder.anchor = Anchor.topLeft;

    final flipperSprite = FlipperSprite(
      position: Vector2(500, 500),
      size: Vector2(300, 100),
      scale: Vector2(1, 1),
      angle: 0,
      flipX: false,
      flipY: false,
    );
    add(flipperSprite);
  }
}
