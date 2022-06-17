import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:smile_game/smile_game.dart';

class Platform extends BodyComponent {
  static Vector2 size = Vector2(2.18, 0.28);

  double x;

  Platform(this.x);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final sprite = await gameRef.loadSprite('platform.png');
    renderBody = false;
    add(
      SpriteComponent(
        sprite: sprite,
        size: size,
        anchor: Anchor.center,
      ),
    );
    //gameRef.camera.followComponent(spriteComponent);
  }

  Vector2 get platformPosition {
    SmileGame game = gameRef as SmileGame;
    return Vector2(x, game.platformPositionY);
  }


  @override
  Body createBody() {
    final shape = PolygonShape()..setAsBoxXY(size.x / 2, size.y / 2);
    final fixtureDef = FixtureDef(
      shape,
      userData: this, // To be able to determine object in collision
    );

    final bodyDef = BodyDef(
      position: platformPosition,
    );

    Body body = world.createBody(bodyDef)..createFixture(fixtureDef);
    return body;
  }

  bool get overlayWorldRightEdge {
    double worldRight = gameRef.camera.position.x + gameRef.camera.gameSize.x;
    double myRight = body.position.x + size.x / 2;
    return myRight > worldRight;

  }

  bool get beyondWorldLeftEdge {
    double worldLeft = gameRef.camera.position.x;
    double myRight = body.position.x + size.x / 2;
    bool b = myRight < worldLeft;
    return b;
  }

}
