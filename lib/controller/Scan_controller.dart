import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFLite();
  }

  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;

  var x, y, w, h = 0.0;
  var label = "";

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(cameras[0], ResolutionPreset.max);
      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            objectDetector(image);
          }
          update();
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission Denied");
    }
  }

  initTFLite() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    var detector = await Tflite.runModelOnFrame(
      bytesList: image.planes.map((e) {
        return e.bytes;
      }).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );

    if (detector != null && detector.isNotEmpty) {
      var ourDetectedObject = detector.first;

      // Ensure 'confidenceInClass' and 'rect' are not null before accessing
      if (ourDetectedObject['confidenceInClass'] != null &&
          ourDetectedObject['rect'] != null) {
        // Check confidence threshold
        if (ourDetectedObject['confidenceInClass'] * 100 > 45) {
          label = ourDetectedObject['detectedClass'].toString();
          h = ourDetectedObject['rect']['h'];
          w = ourDetectedObject['rect']['w'];
          x = ourDetectedObject['rect']['x'];
          y = ourDetectedObject['rect']['y'];
        }
      }
      // else {
      //   debugPrint("EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEe");
      // }
      // Update UI after processing
      update();
    }
  }
}
