// Example usage in your results screen or test completion handler
import 'package:flutter/material.dart';
import 'package:young_refractometry/services/advanced_refraction_service.dart';
import 'package:young_refractometry/models/test_response.dart';
import 'package:young_refractometry/models/eye_result.dart';
import 'package:young_refractometry/models/health_risk_assessment.dart';

// Then paste the rest of the usage example code...

class TestResultsScreen extends StatefulWidget {
  final List<TestResponse> responses;
  final int? patientAge; // Collect this during patient intake
  
  const TestResultsScreen({
    required this.responses,
    this.patientAge,
  });

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  late EyeResult leftEyeResult;
  late EyeResult rightEyeResult;
  HealthRiskAssessment? healthAssessment;
  bool isAccommodating = false;
  String addPower = "0.00";
  
  @override
  void initState() {
    super.initState();
    calculateResults();
  }
  
  void calculateResults() {
    // Separate responses by eye
    final leftEyeResponses = widget.responses.where((r) => r.eye == 'left').toList();
    final rightEyeResponses = widget.responses.where((r) => r.eye == 'right').toList();
    
    // Calculate with accommodation correction enabled
    // Calculate with advanced service
    final leftFull = AdvancedRefractionService.calculateFullAssessment(
      distanceResponses: leftEyeResponses,
      nearResponses: [], 
      age: widget.patientAge ?? 30, // Default for standalone
      eye: 'left',
    );
    leftEyeResult = leftFull.modelResult;
    
    final rightFull = AdvancedRefractionService.calculateFullAssessment(
      distanceResponses: rightEyeResponses,
      nearResponses: [],
      age: widget.patientAge ?? 30,
      eye: 'right',
    );
    rightEyeResult = rightFull.modelResult;
    
    // Use the "worst" case or right eye for general assessment for now
    healthAssessment = rightFull.healthAssessment;
    isAccommodating = rightFull.isAccommodating || leftFull.isAccommodating;
    addPower = rightFull.addPower;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Refraction Results')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient info
            if (widget.patientAge != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Patient Age: ${widget.patientAge} years'),
                ),
              ),
            SizedBox(height: 16),
            
            // Accommodation warning/info
            if (isAccommodating)
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Accommodation Corrected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Result adjusted for accommodative excess.'),
                      SizedBox(height: 8),
                      Text(
                        'True prescription calculated.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),
            
            // Left Eye Results
            ResultCard(
              title: 'Left Eye (OS)',
              result: leftEyeResult,
            ),
            SizedBox(height: 16),
            
            // Right Eye Results
            ResultCard(
              title: 'Right Eye (OD)',
              result: rightEyeResult,
            ),
            SizedBox(height: 24),
            
            // Clinical notes
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Recommendations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildRecommendation(
                      '1. Use these values as a starting point for subjective refraction',
                    ),
                    _buildRecommendation(
                      '2. Perform duochrome test to refine sphere power',
                    ),
                    _buildRecommendation(
                      '3. Verify axis with Jackson Cross Cylinder if cylinder present',
                    ),
                    if (isAccommodating)
                      _buildRecommendation(
                        '4. Consider cycloplegic refraction for accurate hyperopia measurement',
                        color: Colors.orange,
                      ),
                    _buildRecommendation(
                      '5. Trial frame or phoropter refinement recommended before final Rx',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.print),
                    label: Text('Print Results'),
                    onPressed: () => _printResults(),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.share),
                    label: Text('Share with Doctor'),
                    onPressed: () => _shareResults(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendation(String text, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: color)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
  
  void _printResults() {
    // Implement print functionality
  }
  
  void _shareResults() {
    // Implement share functionality
  }
}

class ResultCard extends StatelessWidget {
  final String title;
  final EyeResult result;
  
  const ResultCard({
    required this.title,
    required this.result,
  });
  
  @override
  Widget build(BuildContext context) {
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 24),
            _buildResultRow('Sphere:', result.sphere),
            _buildResultRow('Cylinder:', result.cylinder),
            _buildResultRow('Axis:', '${result.axis}°'),
            Divider(height: 24),
            _buildResultRow('Accuracy:', '${result.accuracy}%'),
            _buildResultRow('Visual Threshold:', result.avgBlur),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rx: ${result.sphere} ${result.cylinder != "0.00" ? result.cylinder : ""} ${result.axis != 0 ? "x ${result.axis}°" : ""}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}