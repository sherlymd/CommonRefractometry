import 'package:flutter/material.dart';
import '../models/test_config.dart';

/// Distance calculation service using IPD (Inter-Pupillary Distance) method
/// 
/// This uses the pinhole camera model:
/// Distance = (Actual IPD × Focal Length) / IPD in Pixels
/// 
/// IPD is more stable than face bounding box because:
/// - It's a consistent biometric measurement (~63mm for adults)
/// - Less affected by face angle/tilt
/// - More precise landmark detection from ML Kit
class DistanceCalculationService {
  
  /// Calculate distance using IPD (Inter-Pupillary Distance) in pixels
  /// Formula: Distance = (avgIPD_cm × focalLength) / ipdPixels
  static double calculateDistanceFromIPD(double ipdPixels) {
    if (ipdPixels <= 0) return 0.0;
    return (TestConfig.avgIPDCm * TestConfig.focalLength) / ipdPixels;
  }
  
  /// Legacy method for backward compatibility (deprecated)
  @Deprecated('Use calculateDistanceFromIPD instead')
  static double calculateDistance(double faceWidthPixels) {
    return (TestConfig.avgFaceWidthCm * TestConfig.focalLength) / faceWidthPixels;
  }
  
  /// Calculate the actual IPD in cm based on detected pixels and distance
  /// This is an estimation for display purposes
  static double calculateActualIPD(double ipdPixels, double distanceCm) {
    if (distanceCm <= 0 || ipdPixels <= 0) return 0.0;
    return (ipdPixels * distanceCm) / TestConfig.focalLength;
  }

  static bool isDistanceValid(double distance) {
    return (distance - TestConfig.targetDistance).abs() <= 
           TestConfig.distanceTolerance;
  }

  static String getDistanceFeedback(double distance) {
    if (distance <= 0) {
      return 'Position your face to detect eyes';
    }
    if (distance < TestConfig.targetDistance - TestConfig.distanceTolerance) {
      return 'Move back - too close!';
    } else if (distance > TestConfig.targetDistance + TestConfig.distanceTolerance) {
      return 'Move closer - too far!';
    }
    return 'Perfect distance!';
  }

  static Color getFeedbackColor(double distance) {
    if (distance <= 0) {
      return const Color(0xFFEF4444); // Red - no detection
    }
    if (isDistanceValid(distance)) {
      return const Color(0xFF10B981); // Green
    }
    return const Color(0xFFF59E0B); // Yellow
  }
  
  /// Get IPD status message
  static String getIPDStatus(double ipdCm, bool eyesDetected) {
    if (!eyesDetected) {
      return 'Eyes not detected';
    }
    if (ipdCm < 4.0 || ipdCm > 8.0) {
      return 'IPD: ${ipdCm.toStringAsFixed(1)} cm (unusual)';
    }
    return 'IPD: ${ipdCm.toStringAsFixed(1)} cm';
  }
}