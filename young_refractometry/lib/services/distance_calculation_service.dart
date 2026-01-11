import 'package:flutter/material.dart';
import '../models/test_config.dart';

class DistanceCalculationService {
  static double calculateDistance(double faceWidthPixels) {
    return (TestConfig.avgFaceWidthCm * TestConfig.focalLength) / 
           faceWidthPixels;
  }

  static bool isDistanceValid(double distance) {
    return (distance - TestConfig.targetDistance).abs() <= 
           TestConfig.distanceTolerance;
  }

  static String getDistanceFeedback(double distance) {
    if (distance < TestConfig.targetDistance - TestConfig.distanceTolerance) {
      return 'Move back - too close!';
    } else if (distance > TestConfig.targetDistance + TestConfig.distanceTolerance) {
      return 'Move closer - too far!';
    }
    return 'Perfect distance!';
  }

  static Color getFeedbackColor(double distance) {
    if (isDistanceValid(distance)) {
      return const Color(0xFF10B981); // Green
    }
    return const Color(0xFFF59E0B); // Yellow
  }
}