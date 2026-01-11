import 'package:flutter/material.dart';
import 'dart:math';
import '../models/test_response.dart';
import '../models/eye_result.dart';
import '../models/test_config.dart';
import '../services/advanced_refraction_service.dart';

class TestProvider with ChangeNotifier {
  String _currentScreen = 'welcome';
  int? _patientAge;
  String _currentEye = 'right';
  double _blurLevel = TestConfig.initialBlur;
  int _round = 1;
  String _direction = 'up';
  List<TestResponse> _responses = [];
  DateTime? _startTime;
  AdvancedEyeResult? _rightEyeResult;
  AdvancedEyeResult? _leftEyeResult;
  int _cantSeeCount = 0;

  // Getters
  String get currentScreen => _currentScreen;
  String get currentEye => _currentEye;
  double get blurLevel => _blurLevel;
  int get round => _round;
  String get direction => _direction;
  List<TestResponse> get responses => _responses;
  EyeResult? get rightEyeResult => _rightEyeResult?.modelResult;
  EyeResult? get leftEyeResult => _leftEyeResult?.modelResult;
  AdvancedEyeResult? get fullRightResult => _rightEyeResult;
  AdvancedEyeResult? get fullLeftResult => _leftEyeResult;
  int? get patientAge => _patientAge;

  void setPatientAge(int? age) {
    _patientAge = age;
    notifyListeners();
  }

  void setScreen(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  void startRound() {
    _startTime = DateTime.now();
    _direction = _generateRandomDirection();
    notifyListeners();
  }

  String _generateRandomDirection() {
    final random = Random();
    return TestConfig.directions[random.nextInt(TestConfig.directions.length)];
  }

  bool handleResponse(String userDirection) {
    if (_startTime == null) return false;

    final responseTime = DateTime.now().difference(_startTime!).inMilliseconds;
    final correct = userDirection == _direction;

    final response = TestResponse(
      round: _round,
      blurLevel: _blurLevel,
      correct: correct,
      responseTime: responseTime,
      direction: _direction,
      userDirection: userDirection,
      eye: currentEye,
    );

    _responses.add(response);

    // Adaptive blur adjustment
    if (correct) {
      _blurLevel = min(TestConfig.maxBlur, _blurLevel + TestConfig.blurIncrement);
      _cantSeeCount = 0; // Reset can't see counter
    } else {
      _blurLevel = max(TestConfig.minBlur, _blurLevel - TestConfig.blurDecrement);
    }

    final isComplete = _round >= TestConfig.maxRounds;
    
    if (!isComplete) {
      _round++;
      startRound();
    }

    notifyListeners();
    return isComplete;
  }

  bool handleCantSeeResponse() {
    if (_startTime == null) return false;

    final responseTime = DateTime.now().difference(_startTime!).inMilliseconds;
    
    // "Can't See" counts as incorrect with special marker
    final response = TestResponse(
      round: _round,
      blurLevel: _blurLevel,
      correct: false,
      responseTime: responseTime,
      direction: _direction,
      userDirection: 'cant_see', // Special marker
      eye: currentEye,
    );

    _responses.add(response);
    _cantSeeCount++;

    // Significant blur reduction when user can't see
    _blurLevel = max(TestConfig.minBlur, _blurLevel - (TestConfig.blurDecrement * 1.5));

    // If user says "can't see" 3+ times, they have significant refractive error
    // End test early for better accuracy
    // Modifying early exit logic:
    // We do NOT want to end early if we haven't tested Near vision yet (which typically starts later).
    // Instead of ending the whole test, we should perhaps skip to next section, but for now, 
    // let's just relax the limit to prevent premature termination before Near data is collected.
    final shouldEndEarly = _cantSeeCount >= 6; // Relaxed limit to ensure we get some data
    // Ideally, we would check if we have done both Dist and Near, but simple relaxation helps.
    final isComplete = _round >= TestConfig.maxRounds || shouldEndEarly;
    
    if (!isComplete) {
      _round++;
      startRound();
    }

    notifyListeners();
    return isComplete;
  }

  void completeEyeTest() {
    // Split responses into Distance and Near
    final distanceResponses = _responses.where((r) {
      final config = TestConfig.getTestRoundConfiguration(r.round, _patientAge);
      return config.testType == TestType.distance;
    }).toList();

    final nearResponses = _responses.where((r) {
      final config = TestConfig.getTestRoundConfiguration(r.round, _patientAge);
      return config.testType == TestType.near;
    }).toList();

    final result = AdvancedRefractionService.calculateFullAssessment(
      distanceResponses: distanceResponses,
      nearResponses: nearResponses,
      age: _patientAge ?? 30, // Default to 30 if null
      eye: _currentEye, // 'Right' or 'Left'
    );


    if (_currentEye == 'right') {
      _rightEyeResult = result;
      setScreen('switch');
    } else {
      _leftEyeResult = result;
      setScreen('results');
    }

    notifyListeners();
  }

  void switchToLeftEye() {
    _currentEye = 'left';
    _resetTest();
    notifyListeners();
  }

  void _resetTest() {
    _round = 1;
    _blurLevel = TestConfig.initialBlur;
    _responses = [];
    _startTime = null;
    _cantSeeCount = 0;
  }

  void resetAll() {
    _currentScreen = 'welcome';
    _currentEye = 'right';
    _rightEyeResult = null;
    _leftEyeResult = null;
    _resetTest();
    notifyListeners();
  }
}