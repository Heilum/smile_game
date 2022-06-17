import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'platform.dart';
import 'smile_hero.dart';

class SmileGame extends Forge2DGame with TapDetector, WidgetsBindingObserver {
  List<Platform> _platforms = [];
  SmileHero? _hero;
  Function() _gameEndCallback;
  Random random = Random();

  SmileGame(this._gameEndCallback) : super(gravity: Vector2(0, 10.0), zoom: 80);

  @override
  Future<void> onLoad() async {
    _starGame();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  onRemove() {
    WidgetsBinding.instance.removeObserver(this);
  }

  void _starGame() {
    placePlatformAt(screenSizeToWorld.x / 2);

    SmileHero face = SmileHero(screenSizeToWorld / 2);
    add(face);
    _hero = face;
  }

  void placePlatformAt(double x) {
    Platform current = Platform(x);
    add(current);
    _platforms.add(current);
  }

  void handlePlatforms() {
    if (_platforms.isNotEmpty) {
      Platform last = _platforms.last;
      last.mounted.whenComplete(() {
        if (last.overlayWorldRightEdge == false) {
          Platform last = _platforms.last;
          double gap = 0; //SmileHero.size.x * (random.nextInt(3)+0.5);
          double nextPosition = last.platformPosition.x + gap + Platform.size.x;

          placePlatformAt(nextPosition);
        }
      });

      Platform first = _platforms.first;
      first.mounted.whenComplete(() {
        if (first.beyondWorldLeftEdge) {
          first.removeFromParent();
          _platforms.remove(first);
        }
      });
    }
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    if (_hero != null && _hero!.firstContact) {
      endGame();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    handlePlatforms();
  }

  void endGame() {
    for (Platform p in _platforms) {
      p.removeFromParent();
    }
    _platforms.clear();
    _hero?.removeFromParent();
    _hero = null;

    _gameEndCallback();
  }

  double get platformPositionY {
    return screenSizeToWorld.y * 0.8;
  }

  Vector2 get screenSizeToWorld => camera.gameSize;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  void onTapDown(TapDownInfo details) async {
    super.onTapDown(details);
    // _hero?.jump();
  }

  void onSmile(double possibility) {
    _hero?.jump(possibility + 1);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (kDebugMode) {
      print("AppLifecycleState = $state");
    }
    if (state != AppLifecycleState.resumed) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }
}
