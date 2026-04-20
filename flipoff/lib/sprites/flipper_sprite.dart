import 'package:flame/components.dart';

class FlipperSprite extends SpriteComponent with HasGameReference {
  static const _imageName = 'flipper.png';

  final bool _initFlipX;
  final bool _initFlipY;

  FlipperSprite({
    required super.position,
    required super.size,
    required super.scale,
    required super.angle,
    required bool flipX,
    required bool flipY,
    super.anchor = Anchor.center,
    super.priority = 5,
  }) : _initFlipX = flipX,
       _initFlipY = flipY;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(_imageName);
    if (_initFlipX) flipHorizontally();
    if (_initFlipY) flipVertically();
  }
}
