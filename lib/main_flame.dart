import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  await FlameAudio.bgm.initialize();
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame with TapDetector {
  late SpriteComponent button;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    FlameAudio.bgm.play("chismis_bg.mp3", volume: .2);

    SpriteComponent background = SpriteComponent()
      ..sprite = await Sprite.load("background_image.png")
      ..size = size;
    add(background);

    button = SpriteComponent()
      ..sprite = await Sprite.load("btn_generate.png")
      ..size = Vector2(100, 32)
      ..position = Vector2((size.x - 100) / 2, size.y - 32 - 30);
    add(button);
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (button.containsPoint(info.eventPosition.widget)) {
      // print("Button Clicked!");
      add(MyWorld());
      // FlameAudio.initialize();
      FlameAudio.play("audio1.mp3");
    }
  }
}

class MyWorld extends Component {
  late SpriteAnimationComponent player;
  @override
  Future<void> onLoad() async {
    super.onLoad();

    final image = await Flame.images.load('sample.png');

    SpriteAnimation playerAnimation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
            amount: 11, stepTime: 0.1, textureSize: Vector2(32, 34)));

    player = SpriteAnimationComponent()
      ..animation = playerAnimation
      ..size = Vector2(45, 54) * 3.0
      ..position = Vector2(0, 100);
    add(player);
  }

  @override
  void update(double dt) {
    player.x += 1;

    if (player.x > 500) {
      if (player.isMounted) {
        remove(player);
      }
    }
  }
}
