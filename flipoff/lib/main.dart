import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
  }
}
