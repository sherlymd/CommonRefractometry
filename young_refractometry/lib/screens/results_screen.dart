import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import '../services/advanced_refraction_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
  }

  
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TestProvider>(context);
    // Use the latest result (likely Left if completed, or Right)
    final result = provider.fullLeftResult ?? provider.fullRightResult;
    final assessment = result?.healthAssessment;
    final isCritical = assessment?.criticalAlert ?? false;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        centerTitle: true,
        backgroundColor: isCritical ? Colors.red.shade700 : null,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => provider.resetAll(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CRITICAL ALERT BANNER
            if (isCritical) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade700, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 60),
                    const SizedBox(height: 12),
                    Text(
                      '🚨 URGENT REFERRAL REQUIRED',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assessment!.overallInterpretation.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Suspected Conditions:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...assessment.identifiedRisks
                              .map((risk) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning, size: 16, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text('${risk.conditionName} (${risk.confidenceScore > 0.7 ? "High" : "Moderate"})')),
                                      ],
                                    ),
                                  )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.local_hospital),
                      label: const Text('REFER TO OPHTHALMOLOGIST NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      ),
                      onPressed: () {
                        _showReferralDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // DISEASE SCREENING CARD (Non-critical)
            if (!isCritical && assessment != null && assessment.identifiedRisks.isNotEmpty) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.health_and_safety, color: Colors.orange.shade700, size: 30),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Pathology Screening Alert',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "ALERT", // Simplified
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Possible conditions detected based on test performance:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...assessment.identifiedRisks
                          .map((risk) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontSize: 16)),
                                    Expanded(child: Text(risk.conditionName)),
                                  ],
                                ),
                              )),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: const Text(
                          '⚠️ Recommendation: Refer to ophthalmologist for comprehensive eye examination including dilated fundus exam, OCT, and visual field testing.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Patient Information
            if (!isCritical) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          const Text(
                            'Patient Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.patientAge != null) ...[
                        _buildInfoRow('Age:', '${provider.patientAge} years'),
                      ],
                        if (result?.addPower != "0.00")
                          _buildInfoRow('Near Vision:', 'Presbyopic'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Clinical Analysis
            if (!isCritical && result != null) ...[
              Card(
                color: result.isAccommodating 
                    ? Colors.amber.shade50 
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            result.isAccommodating 
                                ? Icons.warning_amber 
                                : Icons.check_circle,
                            color: result.isAccommodating 
                                ? Colors.orange.shade700 
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.isAccommodating 
                                  ? 'Accommodation Corrected' 
                                  : 'Clinical Analysis',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.isAccommodating 
                            ? 'Our advanced algorithm detected you were focusing too hard. We have adjusted the result to show your true refractory error.'
                            : 'Your vision test results have been analyzed against clinical standards for your age group.',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (result.addPower != "0.00")
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '👓 Reading Addition (ADD):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Recommended Reading Add: ${result.addPower}D',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Eye Results (only if not critical)
            if (!isCritical) ...[
              if (provider.rightEyeResult != null && provider.rightEyeResult!.sphere != 'REFER') ...[
                const Text(
                  'Right Eye (OD)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ResultCard(result: provider.rightEyeResult!),
                const SizedBox(height: 16),
              ],
              
              if (provider.leftEyeResult != null && provider.leftEyeResult!.sphere != 'REFER') ...[
                const Text(
                  'Left Eye (OS)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ResultCard(result: provider.leftEyeResult!),
                const SizedBox(height: 24),
              ],
            ],
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Test'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => provider.resetAll(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showReferralDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_hospital, color: Colors.red),
            SizedBox(width: 12),
            Text('Urgent Referral Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This patient requires immediate ophthalmology consultation.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Required examinations:'),
            SizedBox(height: 8),
            Text('• Comprehensive dilated fundus examination'),
            Text('• Visual acuity testing (best corrected)'),
            Text('• Intraocular pressure measurement'),
            Text('• OCT (Optical Coherence Tomography)'),
            Text('• Visual field testing'),
            Text('• Fundus photography'),
            SizedBox(height: 16),
            Text(
              '⚠️ Do not attempt spectacle correction until pathology is ruled out.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? Colors.blue.shade900 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final dynamic result;
  
  const _ResultCard({required this.result});
  
  @override
  Widget build(BuildContext context) {
    String sphereValue = result.sphere;
    bool isMyope = sphereValue.startsWith('-');
    bool isHyperope = sphereValue.startsWith('+') && sphereValue != '+0.00';
    bool hasAstigmatism = result.cylinder != '0.00';
    
    String errorType = '';
    Color typeColor = Colors.grey;
    
    if (isMyope) {
      double sphereDiop = double.tryParse(sphereValue) ?? 0;
      if (sphereDiop >= -3.00) {
        errorType = 'Low Myopia';
        typeColor = Colors.blue;
      } else if (sphereDiop >= -6.00) {
        errorType = 'Moderate Myopia';
        typeColor = Colors.blue.shade700;
      } else if (sphereDiop >= -8.00) {
        errorType = 'High Myopia';
        typeColor = Colors.orange;
      } else {
        errorType = 'Extreme Myopia (Pathologic?)';
        typeColor = Colors.red;
      }
    } else if (isHyperope) {
      errorType = 'Hyperopia';
      typeColor = Colors.green;
    } else {
      errorType = 'Emmetropia (Normal)';
      typeColor = Colors.teal;
    }
    
    if (hasAstigmatism) {
      errorType += ' with Astigmatism';
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typeColor.withOpacity(0.5)),
              ),
              child: Text(
                errorType,
                style: TextStyle(
                 color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildRow('Sphere (SPH):', result.sphere, bold: true),
            _buildRow('Cylinder (CYL):', result.cylinder, bold: true),
            _buildRow('Axis:', result.axis != 0 ? '${result.axis}°' : '-', bold: true),
            const Divider(height: 24),
            _buildRow('Test Accuracy:', '${result.accuracy}%'),
            _buildRow('Blur Threshold:', '${result.avgBlur}'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prescription (Rx):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.sphere} ${result.cylinder != "0.00" ? result.cylinder : ""} ${result.axis != 0 ? "x ${result.axis}°" : ""}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 18 : 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}