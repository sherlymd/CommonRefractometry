import 'dart:ui';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'distance_calculation_service.dart';

class FaceDetectionService {
  // Enable landmarks for IPD-based distance calculation
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: true, // Required for IPD calculation
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
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
          'ipdPixels': 0.0,
          'ipdCm': 0.0,
          'eyesDetected': false,
        };
      }

      final face = faces.first;
      
      // Get eye landmarks for IPD calculation
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      
      if (leftEye == null || rightEye == null) {
        // Fallback: eyes not detected, cannot calculate IPD
        return {
          'faceDetected': true,
          'distance': 0.0,
          'distanceValid': false,
          'ipdPixels': 0.0,
          'ipdCm': 0.0,
          'eyesDetected': false,
        };
      }
      
      // Calculate IPD (Inter-Pupillary Distance) in pixels
      // Using Euclidean distance for accuracy even if face is slightly tilted
      final double ipdPixels = sqrt(
        pow(rightEye.position.x - leftEye.position.x, 2) +
        pow(rightEye.position.y - leftEye.position.y, 2)
      );
      
      // Calculate distance using IPD-based formula
      final distance = DistanceCalculationService.calculateDistanceFromIPD(ipdPixels);
      final distanceValid = DistanceCalculationService.isDistanceValid(distance);
      
      // Calculate actual IPD in cm based on known average
      final ipdCm = DistanceCalculationService.calculateActualIPD(ipdPixels, distance);

      return {
        'faceDetected': true,
        'distance': distance,
        'distanceValid': distanceValid,
        'ipdPixels': ipdPixels,
        'ipdCm': ipdCm,
        'eyesDetected': true,
      };
    } catch (e) {
      print('Face detection error: $e');
      return {
        'faceDetected': false,
        'distance': 0.0,
        'distanceValid': false,
        'ipdPixels': 0.0,
        'ipdCm': 0.0,
        'eyesDetected': false,
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