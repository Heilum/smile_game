import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:smile_game/main.dart';

class FaceDetectorView extends StatefulWidget {
  final Function(double) onSmile;

  const FaceDetectorView(this.onSmile, {Key? key}) : super(key: key);

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView>
    with WidgetsBindingObserver {
  CameraController? _controller;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLiveFeed();
  }

  void _startLiveFeed() {
    final camera = frontCamera!;
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final camera = frontCamera!;
    final orientation = await NativeDeviceOrientationCommunicator()
        .orientation(useSensor: true);

    final imageRotation = InputImageRotationValue.fromRawValue(
        orientation == NativeDeviceOrientation.portraitUp
            ? camera.sensorOrientation
            : (orientation == NativeDeviceOrientation.landscapeLeft ? 0 : 180));
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    _processImage(inputImage);
  }

  @override
  Widget build(BuildContext context) {
    var isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    Size mediaSize = MediaQuery.of(context).size;
    if(_controller!.value.isInitialized == false){
      return Container();
    }else{
      return SizedBox(
        width: mediaSize.width,
        height: mediaSize.height,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
              width: isPortrait
                  ? _controller!.value.previewSize!.height
                  : _controller!.value.previewSize!.width,
              height: isPortrait
                  ? _controller!.value.previewSize!.width
                  : _controller!.value.previewSize!.height,
              child: CameraPreview(_controller!)),
        ),
      );
    }

  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("face_detector.didChangeAppLifecycleState.state = $state");
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state != AppLifecycleState.resumed) {
      cameraController.stopImageStream();
    } else {
      cameraController.startImageStream(_processCameraImage);
    }
  }


  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      Face first = faces.first;
      double? smile = first.smilingProbability;
      if (smile != null) {
        widget.onSmile(smile);
      }
    } else {
      if (kDebugMode) {
        print("can't find faces");
      }
    }
    _isBusy = false;
  }
}
