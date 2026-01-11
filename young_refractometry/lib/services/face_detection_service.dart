import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'distance_calculation_service.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: false,
      enableTracking: false,
    ),
  );

  Future<Map<String, dynamic>> detectFaceAndDistance(
    CameraImage image,
  ) async {
    try {
      final inputImage = _convertCameraImage(image);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return {
          'faceDetected': false,
          'distance': 0.0,
          'distanceValid': false,
        };
      }

      final face = faces.first;
      final faceWidthPixels = 
          (face.boundingBox.right - face.boundingBox.left).toDouble();
      
      final distance = 
          DistanceCalculationService.calculateDistance(faceWidthPixels);
      final distanceValid = 
          DistanceCalculationService.isDistanceValid(distance);

      return {
        'faceDetected': true,
        'distance': distance,
        'distanceValid': distanceValid,
      };
    } catch (e) {
      print('Face detection error: $e');
      return {
        'faceDetected': false,
        'distance': 0.0,
        'distanceValid': false,
      };
    }
  }

  InputImage _convertCameraImage(CameraImage image) {
    final bytes = _concatenatePlanes(image.planes);
    
    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation0deg,
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  void dispose() {
    _faceDetector.close();
  }
}