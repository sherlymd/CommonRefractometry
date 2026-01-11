import 'package:young_refractometry/services/advanced_refraction_service.dart';
import 'package:young_refractometry/models/test_response.dart';

void main() {
  print("=== Advanced Refraction Logic Verification ===\n");

  _verifyScenario("A. Healthy Teenager (Latent Hyperopia)", 
    age: 16,
    responses: _generateResponses(accuracy: 1.0, count: 10, blurLimit: 8.0),
    expectedSphere: 0.75, // Should accommodate
    expectedRisk: "Low"
  );
  
  _verifyScenario("B. Presbyope (45yo)", 
    age: 45,
    responses: _generateResponses(accuracy: 0.9, count: 10, blurLimit: 5.0),
    expectedAdd: 1.50, // Approx
    expectedRisk: "Low"
  );

  _verifyScenario("C. ARMD Suspect (65yo)", 
    age: 65,
    responses: _generateResponses(accuracy: 0.4, count: 10, blurLimit: 2.0, cantSeeCount: 5),
    expectedRisk: "High", // ARMD Flag
    expectedCondition: "ARMD"
  );

  _verifyScenario("D. Glaucoma Suspect (50yo - Tunnel Vision)", 
    age: 50,
     // Misses Up/Down (Peripheral) but sees Left/Right
    responses: [
      ..._generateResponses(accuracy: 1.0, count: 5, direction: 'left'),
      ..._generateResponses(accuracy: 0.0, count: 5, direction: 'up'), 
    ],
    expectedRisk: "Moderate",
    expectedCondition: "Glaucoma"
  );
}

void _verifyScenario(String title, {
  required int age, 
  required List<TestResponse> responses,
  double? expectedSphere,
  double? expectedAdd,
  String? expectedRisk,
  String? expectedCondition
}) {
  print("Scenario: $title");
  final result = AdvancedRefractionService.calculateFullAssessment(
    distanceResponses: responses,
    nearResponses: [],
    age: age,
    eye: 'Right'
  );

  print("  -> Sphere: ${result.modelResult.sphere}");
  if (expectedSphere != null) {
    // Basic string parse check
    double got = double.parse(result.modelResult.sphere);
    if ((got - expectedSphere).abs() < 0.25) print("  ✅ Sphere Match");
    else print("  ❌ Sphere Mismatch (Got $got, Exp $expectedSphere)");
  }

  if (age >= 40) {
     print("  -> Add: ${result.addPower}");
     if (expectedAdd != null) {
        double got = double.parse(result.addPower.replaceAll('+',''));
        if ((got - expectedAdd).abs() < 0.25) print("  ✅ ADD Match");
        else print("  ❌ ADD Mismatch (Got $got, Exp $expectedAdd)");
     }
  }

  print("  -> Health Risk: ${result.healthAssessment.overallInterpretation}");
  if (result.healthAssessment.identifiedRisks.isNotEmpty) {
      for (var r in result.healthAssessment.identifiedRisks) {
          print("     - DETECTED: ${r.conditionName} (${r.riskLevel})");
      }
      if (expectedCondition != null) {
         bool found = result.healthAssessment.identifiedRisks
            .any((r) => r.conditionName.contains(expectedCondition));
         if (found) print("  ✅ Condition '$expectedCondition' Detected");
         else print("  ❌ Condition '$expectedCondition' NOT Detected");
      }
  } else if (expectedCondition != null) {
      print("  ❌ Condition '$expectedCondition' expected but NONE detected");
  }

  print("");
}

List<TestResponse> _generateResponses({
  required double accuracy, 
  required int count, 
  double blurLimit = 5.0,
  String? direction,
  int cantSeeCount = 0
}) {
  List<TestResponse> list = [];
  int correctCount = (count * accuracy).round();
  
  for (int i=0; i<count; i++) {
    bool correct = i < correctCount;
    if (i >= count - cantSeeCount) {
       // Append cant see
       list.add(TestResponse(
         eye: 'left',
         round: 1,
         blurLevel: 0, 
         direction: direction ?? 'right', 
         userDirection: 'cant_see', 
         correct: false, 
         responseTime: 1000
       ));
    } else {
       list.add(TestResponse(
         eye: 'left',
         round: 1,
         blurLevel: correct ? blurLimit : 0.0, 
         direction: direction ?? 'right', 
         userDirection: direction ?? 'right', // Dummy
         correct: correct, 
         responseTime: 1000
       ));
    }
  }
  return list;
}
