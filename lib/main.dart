import 'package:camera/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smile_game/face_detector_view.dart';
import 'package:smile_game/smile_game.dart';

List<CameraDescription> cameras = [];
CameraDescription? frontCamera;

enum GameStatus { gaming, end }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  frontCamera = cameras.firstWhere(
      (element) => element.lensDirection == CameraLensDirection.front);

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  SmileGame? _game;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      FaceDetectorView(_onSmile),
      if (_game != null) GameWidget(game: _game!)
    ]);
  }

  void _onSmile(double probability){
    if(probability > 0.6){
      _game?.onSmile(probability);
    }
  }

  void _startGame() {
    setState(() {
      _game = SmileGame(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // executes after build
          _showDialog();
        });

      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // executes after build
      _showDialog();
    });
  }

  Future<void> _showDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Smile Game'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Just smile and let your hero jump'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
                _startGame();
              },
            ),
          ],
        );
      },
    );
  }
}
