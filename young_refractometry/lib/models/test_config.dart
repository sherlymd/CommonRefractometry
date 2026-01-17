import 'dart:ui';

import 'package:flutter/material.dart';

/// Complete presbyopic testing configuration
/// Simulates distance vision (6 meters) and near vision (40cm) testing
/// 
/// CLINICAL RATIONALE:
/// - Young patients (< 40): Distance testing only (full accommodation available)
/// - Presbyopes (40+): Distance + Near testing (accommodation insufficient)
/// - Font sizes calibrated to Snellen (distance) and Jaeger/N notation (near)

class TestConfig {
  static const List<String> directions = ['up', 'down', 'left', 'right'];
  static const int maxRounds = 24; // Extended for comprehensive presbyopic testing
  static const double initialBlur = 0.5;
  static const double minBlur = 0.0;
  static const double maxBlur = 6.0;
  static const double blurIncrement = 0.3;
  static const double blurDecrement = 0.5;
  static const int targetDistance = 40; // cm
  static const int distanceTolerance = 15; // cm
  static const int relaxationTime = 10; // seconds
    // Face Detection
  static const double avgFaceWidthCm = 14.0;
  static const double focalLength = 500.0;
  
  // IPD (Inter-Pupillary Distance) for distance calculation
  // Average adult IPD is approximately 6.3cm (63mm)
  // Range: 5.4cm - 7.5cm for most adults
  static const double avgIPDCm = 6.3;
  
  
  // ═══════════════════════════════════════════════════════════
  // DISTANCE VISION TESTING (Simulates 6 meters / 20 feet)
  // ═══════════════════════════════════════════════════════════
  
  /// Distance vision font sizes (all ages)
  /// These simulate standard Snellen chart at 6 meters
  static  Map<double, String> distanceVisionSizes = {
    150.0: '6/60 (20/200)',    // Legal blindness threshold
    120.0: '6/48 (20/160)',    // Severe visual impairment
    100.0: '6/36 (20/120)',    // Moderate impairment
    80.0:  '6/24 (20/80)',     // Mild impairment
    70.0:  '6/18 (20/60)',     // Borderline
    60.0:  '6/12 (20/40)',     // Driving minimum (some countries)
    50.0:  '6/9 (20/30)',      // Good vision
    40.0:  '6/6 (20/20)',      // Normal vision
  };
  
  // ═══════════════════════════════════════════════════════════
  // NEAR VISION TESTING (Simulates 40cm / 16 inches)
  // ═══════════════════════════════════════════════════════════
  
  /// Near vision font sizes (presbyopes only)
  /// These simulate reading charts at 40cm (Jaeger/N notation)
  static  Map<double, String> nearVisionSizes = {
    70.0: 'N10 / J10 (Large print books)',
    60.0: 'N8 / J8 (Newspaper headlines)',
    50.0: 'N6 / J6 (Standard newspaper text)',
    45.0: 'N5 / J5 (Magazine text)',
    35.0: 'N4 / J4 (Fine print / contracts)',
    28.0: 'N3 / J3 (Medicine bottle labels)',
    20.0: 'N2 / J2 (Very fine print)',
  };
  
  // ═══════════════════════════════════════════════════════════
  // AGE-SPECIFIC TEST PROTOCOLS
  // ═══════════════════════════════════════════════════════════
  
  /// Test protocol for young patients (< 40 years)
  /// Focus: Distance refractive error only
  static List<TestRound> getYoungPatientProtocol() {
    return [
      // Comprehensive distance vision testing
      TestRound(fontSize: 150.0, testType: TestType.distance, difficulty: 'Very Easy'),
      TestRound(fontSize: 120.0, testType: TestType.distance, difficulty: 'Easy'),
      TestRound(fontSize: 100.0, testType: TestType.distance, difficulty: 'Moderate'),
      TestRound(fontSize: 80.0, testType: TestType.distance, difficulty: 'Medium'),
      TestRound(fontSize: 70.0, testType: TestType.distance, difficulty: 'Medium'),
      TestRound(fontSize: 60.0, testType: TestType.distance, difficulty: 'Challenging'),
      TestRound(fontSize: 50.0, testType: TestType.distance, difficulty: 'Difficult'),
      TestRound(fontSize: 40.0, testType: TestType.distance, difficulty: 'Very Difficult'),
      // Repeat key sizes for reliability
      TestRound(fontSize: 100.0, testType: TestType.distance, difficulty: 'Moderate'),
      TestRound(fontSize: 80.0, testType: TestType.distance, difficulty: 'Medium'),
      TestRound(fontSize: 60.0, testType: TestType.distance, difficulty: 'Challenging'),
      TestRound(fontSize: 50.0, testType: TestType.distance, difficulty: 'Difficult'),
    ];
  }
  
  /// Test protocol for early presbyopes (40-49 years)
  /// Focus: Distance + Near (mild presbyopia)
  static List<TestRound> getEarlyPresbyopeProtocol() {
    return [
      // Phase 1: Distance vision assessment (Rounds 1-6)
      TestRound(fontSize: 120.0, testType: TestType.distance, difficulty: 'Easy'),
      TestRound(fontSize: 100.0, testType: TestType.distance, difficulty: 'Moderate'),
      TestRound(fontSize: 80.0, testType: TestType.distance, difficulty: 'Medium'),
      TestRound(fontSize: 70.0, testType: TestType.distance, difficulty: 'Medium'),
      TestRound(fontSize: 60.0, testType: TestType.distance, difficulty: 'Challenging'),
      TestRound(fontSize: 50.0, testType: TestType.distance, difficulty: 'Difficult'),
      
      // Phase 2: Near vision assessment (Rounds 7-12)
      TestRound(fontSize: 70.0, testType: TestType.near, difficulty: 'Easy (N10)'),
      TestRound(fontSize: 60.0, testType: TestType.near, difficulty: 'Moderate (N8)'),
      TestRound(fontSize: 50.0, testType: TestType.near, difficulty: 'Challenging (N6)'),
      TestRound(fontSize: 45.0, testType: TestType.near, difficulty: 'Difficult (N5)'),
      TestRound(fontSize: 35.0, testType: TestType.near, difficulty: 'Very Difficult (N4)'),
      TestRound(fontSize: 28.0, testType: TestType.near, difficulty: 'Extremely Difficult (N3)'),
      
      // Phase 3: Mixed verification (Rounds 13-18)
      TestRound(fontSize: 100.0, testType: TestType.distance, difficulty: 'Distance Check'),
      TestRound(fontSize: 60.0, testType: TestType.near, difficulty: 'Near Check (N8)'),
      TestRound(fontSize: 80.0, testType: TestType.distance, difficulty: 'Distance Check'),
      TestRound(fontSize: 50.0, testType: TestType.near, difficulty: 'Near Check (N6)'),
      TestRound(fontSize: 60.0, testType: TestType.distance, difficulty: 'Distance Check'),
      TestRound(fontSize: 45.0, testType: TestType.near, difficulty: 'Near Check (N5)'),
    ];
  }
  
  /// Test protocol for moderate presbyopes (50-59 years)
  /// Focus: Distance + Near (moderate presbyopia)
  static List<TestRound> getModeratePresbyopeProtocol() {
    return [
      // Phase 1: Distance vision (Rounds 1-5)
      TestRound(fontSize: 120.0, testType: TestType.distance, difficulty: 'Easy'),
      TestRound(fontSize: 100.0, testType: TestType.distance, difficulty: 'Moderate'),
      TestRound(fontSize: 80.0, testType: TestType.distance, difficulty: 'Medium'),
      TestRound(fontSize: 60.0, testType: TestType.distance, difficulty: 'Challenging'),
      TestRound(fontSize: 50.0, testType: TestType.distance, difficulty: 'Difficult'),
      
      // Phase 2: Near vision - MORE emphasis (Rounds 6-14)
      TestRound(fontSize: 70.0, testType: TestType.near, difficulty: 'Easy (N10)'),
      TestRound(fontSize: 60.0, testType: TestType.near, difficulty: 'Moderate (N8)'),
      TestRound(fontSize: 50.0, testType: TestType.near, difficulty: 'Challenging (N6)'),
      TestRound(fontSize: 45.0, testType: TestType.near, difficulty: 'Difficult (N5)'),
      TestRound(fontSize: 35.0, testType: TestType.near, difficulty: 'Very Difficult (N4)'),
      TestRound(fontSize: 28.0, testType: TestType.near, difficulty: 'Extremely Difficult (N3)'),
      TestRound(fontSize: 20.0, testType: TestType.near, difficulty: 'Maximum Difficulty (N2)'),
      // Repeat critical near sizes
      TestRound(fontSize: 50.0, testType: TestType.near, difficulty: 'Near Recheck (N6)'),
      TestRound(fontSize: 45.0, testType: TestType.near, difficulty: 'Near Recheck (N5)'),
      
      // Phase 3: Mixed (Rounds 15-20)
      TestRound(fontSize: 100.0, testType: TestType.distance, difficulty: 'Distance'),
      TestRound(fontSize: 60.0, testType: TestType.near, difficulty: 'Near (N8)'),
      TestRound(fontSize: 80.0, testType: TestType.distance, difficulty: 'Distance'),
      TestRound(fontSize: 45.0, testType: TestType.near, difficulty: 'Near (N5)'),
      TestRound(fontSize: 70.0, testType: TestType.distance, difficulty: 'Distance'),
      TestRound(fontSize: 35.0, testType: TestType.near, difficulty: 'Near (N4)'),
    ];
  }
  
  /// Test protocol for advanced presbyopes (60+ years)
  /// Focus: Distance + Near (advanced presbyopia)
  static List<TestRound> getAdvancedPresbyopeProtocol() {
    return [
      // Phase 1: Distance vision (Rounds 1-4)
      TestRound(fontSize: 120.0, testType: TestType.distance, difficulty: 'Easy'),
      TestRound(fontSize: 100.0, testType: TestType.distance, difficulty: 'Moderate'),
      TestRound(fontSize: 80.0, testType: TestType.distance, difficulty: 'Medium'),
      TestRound(fontSize: 60.0, testType: TestType.distance, difficulty: 'Challenging'),
      
      // Phase 2: Near vision - MAXIMUM emphasis (Rounds 5-16)
      TestRound(fontSize: 70.0, testType: TestType.near, difficulty: 'Large Print (N10)'),
      TestRound(fontSize: 60.0, testType: TestType.near, difficulty: 'Headlines (N8)'),
      TestRound(fontSize: 50.0, testType: TestType.near, difficulty: 'Newspaper (N6)'),
      TestRound(fontSize: 45.0, testType: TestType.near, difficulty: 'Magazine (N5)'),
      TestRound(fontSize: 35.0, testType: TestType.near, difficulty: 'Fine Print (N4)'),
      TestRound(fontSize: 28.0, testType: TestType.near, difficulty: 'Labels (N3)'),
      TestRound(fontSize: 20.0, testType: TestType.near, difficulty: 'Micro Print (N2)'),
      // Multiple repeats for reliability
      TestRound(fontSize: 60.0, testType: TestType.near, difficulty: 'Recheck (N8)'),
      TestRound(fontSize: 50.0, testType: TestType.near, difficulty: 'Recheck (N6)'),
      TestRound(fontSize: 45.0, testType: TestType.near, difficulty: 'Recheck (N5)'),
      TestRound(fontSize: 35.0, testType: TestType.near, difficulty: 'Recheck (N4)'),
      TestRound(fontSize: 28.0, testType: TestType.near, difficulty: 'Recheck (N3)'),
      
      // Phase 3: Final mixed (Rounds 17-22)
      TestRound(fontSize: 100.0, testType: TestType.distance, difficulty: 'Distance'),
      TestRound(fontSize: 60.0, testType: TestType.near, difficulty: 'Near (N8)'),
      TestRound(fontSize: 80.0, testType: TestType.distance, difficulty: 'Distance'),
      TestRound(fontSize: 50.0, testType: TestType.near, difficulty: 'Near (N6)'),
      TestRound(fontSize: 70.0, testType: TestType.distance, difficulty: 'Distance'),
      TestRound(fontSize: 45.0, testType: TestType.near, difficulty: 'Near (N5)'),
    ];
  }
  
  // ═══════════════════════════════════════════════════════════
  // MAIN FONT SIZE GETTER
  // ═══════════════════════════════════════════════════════════
  
  /// Get font size and test type for specific round based on patient age
  static TestRound getTestRoundConfiguration(int round, int? patientAge) {
    List<TestRound> protocol;
    
    if (patientAge == null || patientAge < 40) {
      protocol = getYoungPatientProtocol();
    } else if (patientAge >= 40 && patientAge < 50) {
      protocol = getEarlyPresbyopeProtocol();
    } else if (patientAge >= 50 && patientAge < 60) {
      protocol = getModeratePresbyopeProtocol();
    } else {
      protocol = getAdvancedPresbyopeProtocol();
    }
    
    // Cycle through protocol if round exceeds protocol length
    int index = (round - 1) % protocol.length;
    return protocol[index];
  }
  
  /// Get adjusted font size accounting for blur
  static double getAdjustedFontSize(int round, int? patientAge, double currentBlur) {
    TestRound config = getTestRoundConfiguration(round, patientAge);
    double baseFontSize = config.fontSize;
    
    // Near vision is MORE affected by blur (presbyopes can't accommodate)
    if (config.testType == TestType.near) {
      // Presbyopes with blur struggle more at near
      if (currentBlur > 2.0 && baseFontSize <= 45.0) {
        return baseFontSize * 0.85; // 15% harder
      } else if (currentBlur > 1.5 && baseFontSize <= 35.0) {
        return baseFontSize * 0.90; // 10% harder
      }
    }
    
    return baseFontSize;
  }
  
  // ═══════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════
  
  /// Get Snellen or Jaeger notation for font size
  static String getVisionNotation(double fontSize, TestType testType) {
    if (testType == TestType.distance) {
      return distanceVisionSizes[fontSize] ?? 'Unknown';
    } else {
      return nearVisionSizes[fontSize] ?? 'Unknown';
    }
  }
  
  /// Get user-friendly instruction for current test type
  static String getTestInstruction(TestType testType) {
    if (testType == TestType.distance) {
      return '📍 Hold phone at arm\'s length (60cm)\nFar screen vision test';
    } else {
      return '📖 Hold phone at reading distance (40cm)\nNear vision test';
    }
  }
  
  /// Determine if patient likely has presbyopia based on test performance
  static bool likelyHasPresbyopia(List<dynamic> responses, int? patientAge) {
    if (patientAge == null || patientAge < 40) return false;
    
    int nearVisionAttempts = 0;
    int nearVisionCorrect = 0;
    int distanceVisionAttempts = 0;
    int distanceVisionCorrect = 0;
    
    for (int i = 0; i < responses.length; i++) {
      var response = responses[i];
      TestRound config = getTestRoundConfiguration(i + 1, patientAge);
      
      if (config.testType == TestType.near && config.fontSize <= 50.0) {
        nearVisionAttempts++;
        if (response.correct == true) nearVisionCorrect++;
      } else if (config.testType == TestType.distance) {
        distanceVisionAttempts++;
        if (response.correct == true) distanceVisionCorrect++;
      }
    }
    
    if (nearVisionAttempts == 0) return false;
    
    double nearAccuracy = (nearVisionCorrect / nearVisionAttempts) * 100;
    double distanceAccuracy = distanceVisionAttempts > 0 
        ? (distanceVisionCorrect / distanceVisionAttempts) * 100 
        : 100.0;
    
    // Presbyopia: Good distance, poor near (gap > 20%)
    return (distanceAccuracy - nearAccuracy) > 20.0;
  }
}

// ═══════════════════════════════════════════════════════════
// SUPPORTING CLASSES
// ═══════════════════════════════════════════════════════════

enum TestType {
  distance,  // Distance vision (6 meters simulation)
  near,      // Near vision (40cm simulation)
}

class TestRound {
  final double fontSize;
  final TestType testType;
  final String difficulty;
  
  const TestRound({
    required this.fontSize,
    required this.testType,
    required this.difficulty,
  });
  
  /// Get color coding for UI
  Color getTypeColor() {
    return testType == TestType.distance 
        ? const Color(0xFF2196F3)  // Blue for distance
        : const Color(0xFFFF9800);  // Orange for near
  }
  
  /// Get icon for test type
  IconData getTypeIcon() {
    return testType == TestType.distance 
        ? Icons.remove_red_eye 
        : Icons.menu_book;
  }
  
  /// Get display label
  String getTypeLabel() {
    return testType == TestType.distance 
        ? 'DISTANCE VISION' 
        : 'NEAR VISION (Reading)';
  }
}