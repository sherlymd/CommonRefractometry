
// Enums for standardized risk levels
enum RiskLevel {
  low,
  moderate,
  high,
  critical,
}

// Data class for a specific disease risk
class DiseaseRisk {
  final String conditionName;
  final RiskLevel riskLevel;
  final double confidenceScore; // 0.0 to 1.0
  final List<String> riskFactors;
  final String recommendation;

  DiseaseRisk({
    required this.conditionName,
    required this.riskLevel,
    required this.confidenceScore,
    required this.riskFactors,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
    'conditionName': conditionName,
    'riskLevel': riskLevel.toString().split('.').last,
    'confidenceScore': confidenceScore,
    'riskFactors': riskFactors,
    'recommendation': recommendation,
  };
}

// Comprehensive assessment result
class HealthRiskAssessment {
  final bool criticalAlert;
  final List<DiseaseRisk> identifiedRisks;
  final String timestamp;
  final String overallInterpretation;

  HealthRiskAssessment({
    required this.criticalAlert,
    required this.identifiedRisks,
    required this.overallInterpretation,
    String? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
    'criticalAlert': criticalAlert,
    'identifiedRisks': identifiedRisks.map((r) => r.toJson()).toList(),
    'overallInterpretation': overallInterpretation,
    'timestamp': timestamp,
  };
}
