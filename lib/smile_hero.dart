
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:smile_game/smile_game.dart';

class SmileHero extends BodyComponent with ContactCallbacks {
  static final Vector2 size = Vector2(0.7, 0.7) ;
  static const double speed = 0.5; // move 0.5m/s, to right
  final Vector2 position;
  bool firstContact = false;
  bool contacted = false;
  SmileHero(this.position);

  Vector2 _cameraFollowing = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final sprite = await gameRef.loadSprite('face.png');
    renderBody = false;

    add(
      SpriteComponent(
        sprite: sprite,
        size: size,
        anchor: Anchor.center,
      ),
    );

  }

  @override
  Body createBody() {
    final shape =  CircleShape();
    shape.radius = size.x / 2;
    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      userData: this, // To be able to determine object in collision
    );

    final bodyDef = BodyDef(
      position: position,
      type: BodyType.dynamic,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }



  @override
  void update(double dt){
    super.update(dt);
    mounted.whenComplete((){
      _cameraFollowing.x = body.position.x;
    });

  }

  @override
  void beginContact(Object other, Contact contact) {
    if(firstContact == false){
      _cameraFollowing = body.position.clone();
      SmileGame game = gameRef as SmileGame;
      double offsetY = body.position.y / game.screenSizeToWorld.y;
      double offsetX = body.position.x / game.screenSizeToWorld.x;
      gameRef.camera
          .followVector2(_cameraFollowing, relativeOffset: Anchor(offsetX, offsetY));
      firstContact = true;

      body.applyLinearImpulse(Vector2(1, 0));
    }

    contacted = true;


  }


  @override
  void endContact(Object other,Contact contact){
    contacted = false;
  }

  void jump(double force) {
    if(contacted){
      body.applyLinearImpulse(Vector2(0,-force));
    }

  }
}
