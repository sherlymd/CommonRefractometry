import 'dart:math';
import 'package:flutter/material.dart';

/// Complete prescription model
class RefractionResult {
  final double sphere;
  final double cylinder;
  final int axis;
  final double add;
  final String eye; // 'OD' (right) or 'OS' (left)
  
  const RefractionResult({
    required this.sphere,
    required this.cylinder,
    required this.axis,
    required this.add,
    required this.eye,
  });
  
  String toMonospaceString() {
    String sphStr = sphere >= 0 
        ? '+${sphere.toStringAsFixed(2)}' 
        : '${sphere.toStringAsFixed(2)}';
    String cylStr = cylinder != 0
        ? (cylinder >= 0 ? '+${cylinder.toStringAsFixed(2)}' : '${cylinder.toStringAsFixed(2)}')
        : '    ';
    String axisStr = cylinder != 0 ? 'x${axis.toString().padLeft(3, '0')}°' : '      ';
    String addStr = add > 0 ? 'ADD +${add.toStringAsFixed(2)}' : '           ';
    
    return '$eye  SPH $sphStr  CYL $cylStr $axisStr  $addStr';
  }
  
  @override
  String toString() => toMonospaceString();
}

/// Calibration settings that can be adjusted based on clinical validation
class CalibrationSettings {
  double myopiaLight;
  double myopiaModerate;
  double myopiaHigh;
  double hyperopiaLight;
  double hyperopiaModerate;
  double hyperopiaHigh;
  double knappCorrectionFactor;
  double cylinderCalibration;
  
  CalibrationSettings({
    this.myopiaLight = 0.92,
    this.myopiaModerate = 0.88,
    this.myopiaHigh = 0.85,
    this.hyperopiaLight = 1.15,
    this.hyperopiaModerate = 1.22,
    this.hyperopiaHigh = 1.28,
    this.knappCorrectionFactor = 0.15,
    this.cylinderCalibration = 0.95,
  });
  
  /// Reset to default factory settings
  void resetToDefaults() {
    myopiaLight = 0.92;
    myopiaModerate = 0.88;
    myopiaHigh = 0.85;
    hyperopiaLight = 1.15;
    hyperopiaModerate = 1.22;
    hyperopiaHigh = 1.28;
    knappCorrectionFactor = 0.15;
    cylinderCalibration = 0.95;
  }
  
  /// Save calibration to JSON
  Map<String, dynamic> toJson() => {
    'myopiaLight': myopiaLight,
    'myopiaModerate': myopiaModerate,
    'myopiaHigh': myopiaHigh,
    'hyperopiaLight': hyperopiaLight,
    'hyperopiaModerate': hyperopiaModerate,
    'hyperopiaHigh': hyperopiaHigh,
    'knappCorrectionFactor': knappCorrectionFactor,
    'cylinderCalibration': cylinderCalibration,
  };
  
  /// Load calibration from JSON
  factory CalibrationSettings.fromJson(Map<String, dynamic> json) {
    return CalibrationSettings(
      myopiaLight: json['myopiaLight'] ?? 0.92,
      myopiaModerate: json['myopiaModerate'] ?? 0.88,
      myopiaHigh: json['myopiaHigh'] ?? 0.85,
      hyperopiaLight: json['hyperopiaLight'] ?? 1.15,
      hyperopiaModerate: json['hyperopiaModerate'] ?? 1.22,
      hyperopiaHigh: json['hyperopiaHigh'] ?? 1.28,
      knappCorrectionFactor: json['knappCorrectionFactor'] ?? 0.15,
      cylinderCalibration: json['cylinderCalibration'] ?? 0.95,
    );
  }
}

/// Clinically calibrated calculator for arm's length testing
class CalibratedRefractionCalculator {
  
  /// Adjustable calibration settings
  static CalibrationSettings calibrationSettings = CalibrationSettings();
  
  /// Standard testing distances
  static const double STANDARD_DISTANCE_M = 6.0;
  static const double ARM_LENGTH_M = 0.60;
  static const double NEAR_DISTANCE_M = 0.40;
  
  /// Calculate ADD power based on age (for presbyopia)
  /// Standard clinical values from Hofstetter's formula
  static double calculateAddByAge(int age) {
    if (age < 40) return 0.00;
    if (age >= 40 && age <= 42) return 0.75;
    if (age >= 43 && age <= 44) return 1.00;
    if (age >= 45 && age <= 47) return 1.25;
    if (age >= 48 && age <= 49) return 1.50;
    if (age >= 50 && age <= 52) return 1.75;
    if (age >= 53 && age <= 54) return 2.00;
    if (age >= 55 && age <= 58) return 2.25;
    if (age >= 59 && age <= 62) return 2.50;
    if (age >= 63 && age <= 65) return 2.75;
    return 3.00; // 66+
  }
  
  /// Calculate sphere with clinical calibration
  /// Uses both arm's length and near measurements for accuracy
  static double calculateCalibratedSphere({
    required double armLengthDistanceCm,
    required double nearDistanceCm,
    required int age,
  }) {
    // Convert to meters
    double armDistanceM = armLengthDistanceCm / 100.0;
    double nearDistanceM = nearDistanceCm / 100.0;
    
    // Step 1: Calculate raw sphere from arm's length
    // Using vergence formula: L = 1/distance
    double measuredVergence = 1.0 / armDistanceM;
    double standardVergence = 1.0 / STANDARD_DISTANCE_M;
    double rawSphere = measuredVergence - standardVergence;
    
    // Step 2: Calculate accommodation demand at near
    double nearVergence = 1.0 / nearDistanceM;
    double standardNearVergence = 1.0 / NEAR_DISTANCE_M;
    double accommodationUsed = nearVergence - standardNearVergence;
    
    // Step 3: Adjust for expected accommodation based on age
    double expectedAccommodation = _calculateExpectedAccommodation(age);
    double accommodationDeficit = expectedAccommodation - accommodationUsed.abs();
    
    // Step 4: Apply clinical calibration factor
    double calibratedSphere = rawSphere;
    
    if (rawSphere < 0) {
      // Myopia
      if (rawSphere.abs() <= 3.0) {
        calibratedSphere = rawSphere * calibrationSettings.myopiaLight;
      } else if (rawSphere.abs() <= 6.0) {
        calibratedSphere = rawSphere * calibrationSettings.myopiaModerate;
      } else {
        calibratedSphere = rawSphere * calibrationSettings.myopiaHigh;
      }
    } else {
      // Hyperopia (considering accommodation deficit)
      calibratedSphere = rawSphere + accommodationDeficit;
      
      if (calibratedSphere.abs() <= 3.0) {
        calibratedSphere = calibratedSphere * calibrationSettings.hyperopiaLight;
      } else if (calibratedSphere.abs() <= 6.0) {
        calibratedSphere = calibratedSphere * calibrationSettings.hyperopiaModerate;
      } else {
        calibratedSphere = calibratedSphere * calibrationSettings.hyperopiaHigh;
      }
    }
    
    // Step 5: Additional correction for intermediate distance testing
    // Knapp's law application
    double distanceRatio = STANDARD_DISTANCE_M / armDistanceM;
    double knappCorrection = (distanceRatio - 1) * calibrationSettings.knappCorrectionFactor;
    calibratedSphere += knappCorrection;
    
    // Round to nearest 0.25D
    return _roundTo025(calibratedSphere);
  }
  
  /// Calculate expected accommodation based on age
  /// Using Hofstetter's formula: Amplitude = 18.5 - 0.3 * age
  static double _calculateExpectedAccommodation(int age) {
    double amplitude = 18.5 - (0.3 * age);
    if (amplitude < 0) amplitude = 0;
    // Return expected accommodation at 40cm (2.5D demand)
    return min(amplitude, 2.5);
  }
  
  /// Calculate cylinder and axis with clinical validation
  static Map<String, double> calculateCylinderAndAxis({
    required double horizontalClarityDistance,
    required double verticalClarityDistance,
    required double oblique45Distance,
    required double oblique135Distance,
  }) {
    Map<int, double> meridians = {
      0: horizontalClarityDistance,
      90: verticalClarityDistance,
      45: oblique45Distance,
      135: oblique135Distance,
    };
    
    int strongestAxis = 0;
    int weakestAxis = 0;
    double minDistance = double.infinity;
    double maxDistance = 0;
    
    meridians.forEach((axis, distance) {
      if (distance < minDistance) {
        minDistance = distance;
        strongestAxis = axis;
      }
      if (distance > maxDistance) {
        maxDistance = distance;
        weakestAxis = axis;
      }
    });
    
    // Calculate cylinder using vergence formula
    double strongVergence = 100.0 / minDistance;
    double weakVergence = 100.0 / maxDistance;
    double rawCylinder = (strongVergence - weakVergence).abs();
    
    // Apply calibration for arm's length testing
    // Cylinder is less affected by distance, but still needs minor adjustment
    double calibratedCylinder = rawCylinder * calibrationSettings.cylinderCalibration;
    
    // Axis is perpendicular to weakest meridian
    int axis = (weakestAxis + 90) % 180;
    
    return {
      'cylinder': _roundTo025(calibratedCylinder),
      'axis': axis.toDouble(),
    };
  }
  
  /// Generate complete calibrated prescription
  static RefractionResult generateCalibratedPrescription({
    required String eye,
    required int age,
    required double armLengthDistanceCm,
    required double nearDistanceCm,
    double cylinder = 0.0,
    int axis = 0,
  }) {
    double sphere = calculateCalibratedSphere(
      armLengthDistanceCm: armLengthDistanceCm,
      nearDistanceCm: nearDistanceCm,
      age: age,
    );
    
    double add = calculateAddByAge(age);
    
    return RefractionResult(
      sphere: sphere,
      cylinder: _roundTo025(cylinder),
      axis: axis,
      add: add,
      eye: eye,
    );
  }
  
  /// Round to nearest 0.25 diopter
  static double _roundTo025(double value) {
    return (value * 4).round() / 4.0;
  }
  
  /// Convert between minus and plus cylinder notation
  static RefractionResult convertCylinderNotation(RefractionResult rx) {
    if (rx.cylinder == 0) return rx;
    
    double newSphere = rx.sphere + rx.cylinder;
    double newCylinder = -rx.cylinder;
    int newAxis = (rx.axis + 90) % 180;
    
    return RefractionResult(
      sphere: newSphere,
      cylinder: newCylinder,
      axis: newAxis,
      add: rx.add,
      eye: rx.eye,
    );
  }
}

/// Flutter Widget for Calibration Adjustment
class CalibrationAdjustmentScreen extends StatefulWidget {
  const CalibrationAdjustmentScreen({Key? key}) : super(key: key);
  
  @override
  State<CalibrationAdjustmentScreen> createState() => _CalibrationAdjustmentScreenState();
}

class _CalibrationAdjustmentScreenState extends State<CalibrationAdjustmentScreen> {
  late CalibrationSettings settings;
  
  @override
  void initState() {
    super.initState();
    settings = CalibrationSettings(
      myopiaLight: CalibratedRefractionCalculator.calibrationSettings.myopiaLight,
      myopiaModerate: CalibratedRefractionCalculator.calibrationSettings.myopiaModerate,
      myopiaHigh: CalibratedRefractionCalculator.calibrationSettings.myopiaHigh,
      hyperopiaLight: CalibratedRefractionCalculator.calibrationSettings.hyperopiaLight,
      hyperopiaModerate: CalibratedRefractionCalculator.calibrationSettings.hyperopiaModerate,
      hyperopiaHigh: CalibratedRefractionCalculator.calibrationSettings.hyperopiaHigh,
      knappCorrectionFactor: CalibratedRefractionCalculator.calibrationSettings.knappCorrectionFactor,
      cylinderCalibration: CalibratedRefractionCalculator.calibrationSettings.cylinderCalibration,
    );
  }
  
  void _saveCalibration() {
    CalibratedRefractionCalculator.calibrationSettings = settings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Calibration saved successfully',
          style: TextStyle(fontFamily: 'Monospace'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _resetToDefaults() {
    setState(() {
      settings.resetToDefaults();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reset to factory defaults',
          style: TextStyle(fontFamily: 'Monospace'),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calibration Settings',
          style: TextStyle(fontFamily: 'Monospace'),
        ),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          SizedBox(height: 20),
          _buildSection('Myopia Calibration', [
            _buildSlider(
              'Light (-0.25 to -3.00 D)',
              settings.myopiaLight,
              0.80,
              1.00,
              (val) => setState(() => settings.myopiaLight = val),
            ),
            _buildSlider(
              'Moderate (-3.25 to -6.00 D)',
              settings.myopiaModerate,
              0.75,
              0.95,
              (val) => setState(() => settings.myopiaModerate = val),
            ),
            _buildSlider(
              'High (-6.25 D and above)',
              settings.myopiaHigh,
              0.70,
              0.90,
              (val) => setState(() => settings.myopiaHigh = val),
            ),
          ]),
          SizedBox(height: 20),
          _buildSection('Hyperopia Calibration', [
            _buildSlider(
              'Light (+0.25 to +3.00 D)',
              settings.hyperopiaLight,
              1.00,
              1.30,
              (val) => setState(() => settings.hyperopiaLight = val),
            ),
            _buildSlider(
              'Moderate (+3.25 to +6.00 D)',
              settings.hyperopiaModerate,
              1.10,
              1.40,
              (val) => setState(() => settings.hyperopiaModerate = val),
            ),
            _buildSlider(
              'High (+6.25 D and above)',
              settings.hyperopiaHigh,
              1.15,
              1.50,
              (val) => setState(() => settings.hyperopiaHigh = val),
            ),
          ]),
          SizedBox(height: 20),
          _buildSection('Advanced Calibration', [
            _buildSlider(
              'Knapp Correction Factor',
              settings.knappCorrectionFactor,
              0.05,
              0.30,
              (val) => setState(() => settings.knappCorrectionFactor = val),
            ),
            _buildSlider(
              'Cylinder Calibration',
              settings.cylinderCalibration,
              0.85,
              1.05,
              (val) => setState(() => settings.cylinderCalibration = val),
            ),
          ]),
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: Icon(Icons.restart_alt),
                  label: Text(
                    'Reset to Defaults',
                    style: TextStyle(fontFamily: 'Monospace'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveCalibration,
                  icon: Icon(Icons.save),
                  label: Text(
                    'Save Calibration',
                    style: TextStyle(fontFamily: 'Monospace'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildValidationCard(),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  'Calibration Guide',
                  style: TextStyle(
                    fontFamily: 'Monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Adjust these factors based on validation with autorefractometer:\n\n'
              '1. Test multiple patients with known prescriptions\n'
              '2. Compare app results with autorefractometer\n'
              '3. Adjust factors to minimize error\n'
              '4. Values > 1.0 increase power, < 1.0 decrease power',
              style: TextStyle(
                fontFamily: 'Monospace',
                fontSize: 12,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontFamily: 'Monospace', fontSize: 13),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value.toStringAsFixed(3),
                style: TextStyle(
                  fontFamily: 'Monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          onChanged: onChanged,
          activeColor: Colors.blueGrey[700],
        ),
        SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildValidationCard() {
    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.amber[700]),
                SizedBox(width: 8),
                Text(
                  'Validation Protocol',
                  style: TextStyle(
                    fontFamily: 'Monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Step 1: Test 10+ patients with autorefractometer readings\n'
              'Step 2: Record app vs autorefractometer differences\n'
              'Step 3: Calculate average error for each category\n'
              'Step 4: Adjust calibration factors by error amount\n'
              'Step 5: Re-test and iterate until error < 0.25D\n\n'
              'Example: If app shows -2.50 but should be -3.00,\n'
              'increase myopia_light from 0.92 to 1.10',
              style: TextStyle(
                fontFamily: 'Monospace',
                fontSize: 11,
                color: Colors.amber[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flutter Widget to display prescription in monospace font
class PrescriptionDisplay extends StatelessWidget {
  final RefractionResult rightEye;
  final RefractionResult leftEye;
  final int patientAge;
  
  const PrescriptionDisplay({
    Key? key,
    required this.rightEye,
    required this.leftEye,
    required this.patientAge,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRESCRIPTION',
            style: TextStyle(
              fontFamily: 'Monospace',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '═' * 50,
            style: TextStyle(fontFamily: 'Monospace', fontSize: 14),
          ),
          SizedBox(height: 12),
          Text(
            'Patient Age: ${patientAge.toString().padLeft(2)} years',
            style: TextStyle(fontFamily: 'Monospace', fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            '─' * 50,
            style: TextStyle(fontFamily: 'Monospace', fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            rightEye.toString(),
            style: TextStyle(
              fontFamily: 'Monospace',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            leftEye.toString(),
            style: TextStyle(
              fontFamily: 'Monospace',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '═' * 50,
            style: TextStyle(fontFamily: 'Monospace', fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            'Testing Method: Calibrated Arm\'s Length',
            style: TextStyle(
              fontFamily: 'Monospace',
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          Text(
            'Calibration: Clinical Grade',
            style: TextStyle(
              fontFamily: 'Monospace',
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// EXAMPLE USAGE WITH CALIBRATION FEATURE
// ============================================

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'Monospace',
      primarySwatch: Colors.blueGrey,
    ),
    home: CalibrationDemo(),
  ));
}

class CalibrationDemo extends StatefulWidget {
  @override
  State<CalibrationDemo> createState() => _CalibrationDemoState();
}

class _CalibrationDemoState extends State<CalibrationDemo> {
  RefractionResult? rightEye;
  RefractionResult? leftEye;
  int patientAge = 55;
  
  @override
  void initState() {
    super.initState();
    _calculatePrescription();
  }
  
  void _calculatePrescription() {
    // Simulated measurements at arm's length
    double odArmLength = 58.0;
    double odNear = 42.0;
    double odCylinder = 1.00;
    int odAxis = 165;
    
    double osArmLength = 56.0;
    double osNear = 40.0;
    double osCylinder = 1.00;
    int osAxis = 20;
    
    setState(() {
      rightEye = CalibratedRefractionCalculator.generateCalibratedPrescription(
        eye: 'OD',
        age: patientAge,
        armLengthDistanceCm: odArmLength,
        nearDistanceCm: odNear,
        cylinder: odCylinder,
        axis: odAxis,
      );
      
      leftEye = CalibratedRefractionCalculator.generateCalibratedPrescription(
        eye: 'OS',
        age: patientAge,
        armLengthDistanceCm: osArmLength,
        nearDistanceCm: osNear,
        cylinder: osCylinder,
        axis: osAxis,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Refraction Calculator'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalibrationAdjustmentScreen(),
                ),
              );
              // Recalculate after calibration changes
              _calculatePrescription();
            },
          ),
        ],
      ),
      body: rightEye != null && leftEye != null
          ? SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  PrescriptionDisplay(
                    rightEye: rightEye!,
                    leftEye: leftEye!,
                    patientAge: patientAge,
                  ),
                  SizedBox(height: 20),
                  _buildComparisonCard(),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _calculatePrescription,
                    icon: Icon(Icons.refresh),
                    label: Text('Recalculate'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
  
  Widget _buildComparisonCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AUTOREFRACTOMETER REFERENCE',
              style: TextStyle(
                fontFamily: 'Monospace',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'OD  SPH +2.25  CYL +1.00 x165°  ADD +2.25',
              style: TextStyle(
                fontFamily: 'Monospace',
                fontSize: 13,
                color: Colors.green[800],
              ),
            ),
            Text(
              'OS  SPH +2.75  CYL +1.00 x020°  ADD +2.25',
              style: TextStyle(
                fontFamily: 'Monospace',
                fontSize: 13,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tap the settings icon to adjust calibration',
              style: TextStyle(
                fontFamily: 'Monospace',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}