import '../models/test_response.dart';
import '../models/eye_result.dart';
import 'dart:math' show min, max;

class RefractionCalculationService {
  /// Enhanced calculation with disease screening capabilities
  static EyeResult calculateRefraction(
    List<TestResponse> responses,
    String eye, {
    int? patientAge,
    bool applyAccommodationCorrection = true,
  }) {
    if (responses.isEmpty) {
      return EyeResult(
        eye: eye,
        sphere: '0.00',
        cylinder: '0.00',
        axis: 0,
        accuracy: '0.0',
        avgBlur: '0.00',
      );
    }

    // ═══════════════════════════════════════════════════════════
    // STEP 1: DISEASE SCREENING - Critical Patterns
    // ═══════════════════════════════════════════════════════════
    
    final diseaseScreening = _screenForDiseases(responses, patientAge);
    
    // If severe pathology suspected, return warning result
    if (diseaseScreening['critical_alert'] == true) {
      return EyeResult(
        eye: eye,
        sphere: 'REFER',
        cylinder: 'URGENT',
        axis: 0,
        accuracy: diseaseScreening['accuracy'].toStringAsFixed(1),
        avgBlur: 'SEE NOTES',
      );
    }

    final correctResponses = responses.where((r) => r.correct).toList();
    final incorrectResponses = responses.where((r) => !r.correct).toList();
    final cantSeeResponses = responses.where((r) => r.userDirection == 'cant_see').toList();
    
    final totalResponses = responses.length;
    final correctCount = correctResponses.length;
    final accuracy = (correctCount / totalResponses) * 100;
    
    // Calculate blur thresholds
    double minFailBlur = 6.0;
    double firstCantSeeBlur = 6.0;
    double maxSuccessBlur = 0.0;
    
    for (var response in incorrectResponses) {
      if (response.blurLevel < minFailBlur) {
        minFailBlur = response.blurLevel;
      }
    }
    
    if (cantSeeResponses.isNotEmpty) {
      firstCantSeeBlur = cantSeeResponses.first.blurLevel;
    }
    
    for (var response in correctResponses) {
      if (response.blurLevel > maxSuccessBlur) {
        maxSuccessBlur = response.blurLevel;
      }
    }

    double visualThreshold = maxSuccessBlur;
    if (cantSeeResponses.isNotEmpty) {
      visualThreshold = min(maxSuccessBlur, firstCantSeeBlur - 0.3);
    } else if (incorrectResponses.isNotEmpty) {
      visualThreshold = (maxSuccessBlur + minFailBlur) / 2;
    }

    // ═══════════════════════════════════════════════════════════
    // ASTIGMATISM ANALYSIS
    // ═══════════════════════════════════════════════════════════
    
    final validResponses = responses.where((r) => r.userDirection != 'cant_see').toList();
    
    final horizontalResponses = validResponses.where((r) => 
        r.direction == 'left' || r.direction == 'right').toList();
    final horizontalCorrect = horizontalResponses.where((r) => r.correct).length;
    final horizontalTotal = horizontalResponses.length;
    final horizontalIncorrect = horizontalResponses.where((r) => !r.correct).toList();
    
    final verticalResponses = validResponses.where((r) => 
        r.direction == 'up' || r.direction == 'down').toList();
    final verticalCorrect = verticalResponses.where((r) => r.correct).length;
    final verticalTotal = verticalResponses.length;
    final verticalIncorrect = verticalResponses.where((r) => !r.correct).toList();

    double horizontalAccuracy = horizontalTotal > 0 
        ? (horizontalCorrect / horizontalTotal) * 100 
        : 100;
    double verticalAccuracy = verticalTotal > 0 
        ? (verticalCorrect / verticalTotal) * 100 
        : 100;

    double maxHorizontalBlur = 0;
    for (var r in horizontalResponses.where((r) => r.correct)) {
      if (r.blurLevel > maxHorizontalBlur) maxHorizontalBlur = r.blurLevel;
    }

    double maxVerticalBlur = 0;
    for (var r in verticalResponses.where((r) => r.correct)) {
      if (r.blurLevel > maxVerticalBlur) maxVerticalBlur = r.blurLevel;
    }

    double minHorizontalFailBlur = 6.0;
    for (var r in horizontalIncorrect) {
      if (r.blurLevel < minHorizontalFailBlur) minHorizontalFailBlur = r.blurLevel;
    }

    double minVerticalFailBlur = 6.0;
    for (var r in verticalIncorrect) {
      if (r.blurLevel < minVerticalFailBlur) minVerticalFailBlur = r.blurLevel;
    }

    double horizontalThreshold = horizontalIncorrect.isEmpty 
        ? maxHorizontalBlur 
        : (maxHorizontalBlur + minHorizontalFailBlur) / 2;
    double verticalThreshold = verticalIncorrect.isEmpty 
        ? maxVerticalBlur 
        : (maxVerticalBlur + minVerticalFailBlur) / 2;

    double accuracyDiff = (horizontalAccuracy - verticalAccuracy).abs();
    double blurDiff = (maxHorizontalBlur - maxVerticalBlur).abs();
    double thresholdDiff = (horizontalThreshold - verticalThreshold).abs();

    // ═══════════════════════════════════════════════════════════
    // AGE-BASED ACCOMMODATION
    // ═══════════════════════════════════════════════════════════
    
    double maxAccommodationCapacity = 7.0;
    String ageGroup = 'unknown';
    
    if (patientAge != null) {
      if (patientAge <= 25) {
        maxAccommodationCapacity = 10.0;
        ageGroup = 'young';
      } else if (patientAge <= 35) {
        maxAccommodationCapacity = 7.0;
        ageGroup = 'adult';
      } else if (patientAge <= 40) {
        maxAccommodationCapacity = 5.0;
        ageGroup = 'pre-presbyope';
      } else if (patientAge <= 45) {
        maxAccommodationCapacity = 3.5;
        ageGroup = 'early-presbyope';
      } else if (patientAge <= 50) {
        maxAccommodationCapacity = 2.0;
        ageGroup = 'presbyope';
      } else if (patientAge <= 55) {
        maxAccommodationCapacity = 1.0;
        ageGroup = 'presbyope';
      } else {
        maxAccommodationCapacity = 0.5;
        ageGroup = 'late-presbyope';
      }
    }

    bool likelyAccommodating = false;
    double estimatedAccommodation = 0.0;
    
    int cantSeeCount = cantSeeResponses.length;
    
    if (accuracy >= 90.0 && visualThreshold >= 4.0 && cantSeeCount == 0) {
      likelyAccommodating = true;
      estimatedAccommodation = maxAccommodationCapacity * 0.25;
      if (estimatedAccommodation < 0.50) estimatedAccommodation = 0.50;
      if (estimatedAccommodation > 2.00) estimatedAccommodation = 2.00;
    } else if (accuracy >= 85.0 && visualThreshold >= 4.5 && cantSeeCount <= 1) {
      likelyAccommodating = true;
      estimatedAccommodation = maxAccommodationCapacity * 0.20;
      if (estimatedAccommodation < 0.50) estimatedAccommodation = 0.50;
      if (estimatedAccommodation > 1.50) estimatedAccommodation = 1.50;
    } else if (accuracy >= 95.0 && visualThreshold >= 3.5 && cantSeeCount == 0) {
      likelyAccommodating = true;
      estimatedAccommodation = maxAccommodationCapacity * 0.15;
      if (estimatedAccommodation < 0.25) estimatedAccommodation = 0.25;
      if (estimatedAccommodation > 1.00) estimatedAccommodation = 1.00;
    }

    if (ageGroup == 'presbyope' || ageGroup == 'late-presbyope') {
      estimatedAccommodation *= 0.5;
    }

    // ═══════════════════════════════════════════════════════════
    // SPHERE CALCULATION
    // ═══════════════════════════════════════════════════════════
    
    double sphere = 0.00;
    
    if (accuracy >= 85.0) {
      if (visualThreshold >= 4.5) {
        if (likelyAccommodating && applyAccommodationCorrection) {
          sphere = estimatedAccommodation;
        } else {
          sphere = 0.00;
        }
      } else if (visualThreshold >= 3.5) {
        if (likelyAccommodating && applyAccommodationCorrection) {
          sphere = estimatedAccommodation * 0.75;
        } else {
          sphere = 0.00;
        }
      } else if (visualThreshold >= 2.8) {
        sphere = likelyAccommodating ? 0.25 : -0.25;
      } else if (visualThreshold >= 2.2) {
        sphere = -0.25;
      } else if (visualThreshold >= 1.8) {
        sphere = -0.50;
      } else if (visualThreshold >= 1.4) {
        sphere = -0.75;
      } else {
        sphere = -1.00;
      }
    } else if (accuracy >= 70.0) {
      if (cantSeeCount >= 3) {
        sphere = -2.50;
      } else if (cantSeeCount >= 2) {
        sphere = -2.00;
      } else if (visualThreshold >= 3.5) {
        sphere = likelyAccommodating ? 0.50 : -0.50;
      } else if (visualThreshold >= 2.5) {
        sphere = -1.00;
      } else if (visualThreshold >= 1.8) {
        sphere = -1.50;
      } else if (visualThreshold >= 1.2) {
        sphere = -2.00;
      } else {
        sphere = -2.50;
      }
    } else if (accuracy >= 50.0) {
      if (cantSeeCount >= 3) {
        sphere = -3.50;
      } else if (cantSeeCount >= 2) {
        sphere = -3.00;
      } else if (visualThreshold >= 2.5) {
        sphere = -1.50;
      } else if (visualThreshold >= 1.8) {
        sphere = -2.50;
      } else if (visualThreshold >= 1.2) {
        sphere = -3.00;
      } else {
        sphere = -3.50;
      }
    } else if (accuracy >= 30.0) {
      // Very poor vision - likely high myope
      if (cantSeeCount >= 5) {
        sphere = -7.00;
      } else if (cantSeeCount >= 4) {
        sphere = -6.00;
      } else if (cantSeeCount >= 3) {
        sphere = -5.00;
      } else {
        sphere = -4.50;
      }
    } else if (accuracy >= 15.0) {
      // Severe visual impairment - extreme myopia or pathology
      sphere = -8.50;
    } else {
      // Critical - possible pathology or no light perception
      sphere = -10.00;
    }

    // ═══════════════════════════════════════════════════════════
    // CYLINDER CALCULATION
    // ═══════════════════════════════════════════════════════════
    
    double cylinder = 0.00;
    int axis = 0;
    bool hasAstigmatism = false;
    
    bool criterion1 = accuracyDiff >= 20;
    bool criterion2 = blurDiff >= 1.5;
    bool criterion3 = thresholdDiff >= 1.2;
    bool criterion4 = (accuracyDiff >= 15 && blurDiff >= 1.0);
    bool criterion5 = (accuracyDiff >= 25 && thresholdDiff >= 0.8);
    
    if (criterion1 || criterion2 || (accuracyDiff >= 35 || blurDiff >= 2.0)) {
      hasAstigmatism = true;
      if (accuracyDiff >= 60 || blurDiff >= 4.0) {
        cylinder = 3.50; // Very high astigmatism
      } else if (accuracyDiff >= 50 || blurDiff >= 3.0) {
        cylinder = 2.50;
      } else if (accuracyDiff >= 40 || blurDiff >= 2.5) {
        cylinder = 1.50;
      } else {
        cylinder = 1.00;
      }
    } else if (criterion3 || criterion4 || criterion5) {
      hasAstigmatism = true;
      if (accuracyDiff >= 30 || blurDiff >= 2.0 || thresholdDiff >= 1.8) {
        cylinder = 0.75;
      } else {
        cylinder = 0.50;
      }
    } else if (accuracyDiff >= 15 || blurDiff >= 0.8 || thresholdDiff >= 1.0) {
      hasAstigmatism = true;
      cylinder = 0.25;
    }
    
    if (hasAstigmatism) {
      double horizontalWeaknessScore = 0;
      double verticalWeaknessScore = 0;
      
      if (horizontalAccuracy < verticalAccuracy) {
        horizontalWeaknessScore += (verticalAccuracy - horizontalAccuracy) * 0.4;
      } else {
        verticalWeaknessScore += (horizontalAccuracy - verticalAccuracy) * 0.4;
      }
      
      if (maxHorizontalBlur < maxVerticalBlur) {
        horizontalWeaknessScore += (maxVerticalBlur - maxHorizontalBlur) * 0.3 * 10;
      } else {
        verticalWeaknessScore += (maxHorizontalBlur - maxVerticalBlur) * 0.3 * 10;
      }
      
      if (horizontalThreshold < verticalThreshold) {
        horizontalWeaknessScore += (verticalThreshold - horizontalThreshold) * 0.3 * 10;
      } else {
        verticalWeaknessScore += (horizontalThreshold - verticalThreshold) * 0.3 * 10;
      }
      
      if (horizontalWeaknessScore > verticalWeaknessScore + 2) {
        axis = 180;
      } else if (verticalWeaknessScore > horizontalWeaknessScore + 2) {
        axis = 90;
      } else {
        if (accuracyDiff > max(blurDiff * 10, thresholdDiff * 10)) {
          axis = horizontalAccuracy < verticalAccuracy ? 180 : 90;
        } else if (blurDiff > thresholdDiff) {
          axis = maxHorizontalBlur < maxVerticalBlur ? 180 : 90;
        } else {
          axis = horizontalThreshold < verticalThreshold ? 180 : 90;
        }
      }
    }

    // ═══════════════════════════════════════════════════════════
    // FINAL FORMATTING
    // ═══════════════════════════════════════════════════════════
    
    sphere = (sphere * 4).roundToDouble() / 4;
    cylinder = (cylinder * 4).roundToDouble() / 4;
    
    if (cylinder > 4.00) cylinder = 4.00;
    if (sphere < -12.00) sphere = -12.00;
    if (sphere > 6.00) sphere = 6.00;
    
    if (cylinder == 0.00) {
      axis = 0;
      hasAstigmatism = false;
    }
    
    String sphereStr = sphere >= 0 
        ? '+${sphere.toStringAsFixed(2)}' 
        : sphere.toStringAsFixed(2);
    
    String cylinderStr = cylinder > 0 
        ? '+${cylinder.toStringAsFixed(2)}' 
        : '0.00';
    
    return EyeResult(
      eye: eye,
      sphere: sphereStr,
      cylinder: cylinderStr,
      axis: axis,
      accuracy: accuracy.toStringAsFixed(1),
      avgBlur: visualThreshold.toStringAsFixed(2),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // DISEASE SCREENING MODULE
  // ═══════════════════════════════════════════════════════════
  
  static Map<String, dynamic> _screenForDiseases(
    List<TestResponse> responses,
    int? patientAge,
  ) {
    final correctResponses = responses.where((r) => r.correct).toList();
    final cantSeeResponses = responses.where((r) => r.userDirection == 'cant_see').toList();
    
    double accuracy = responses.isEmpty ? 0 : (correctResponses.length / responses.length) * 100;
    int cantSeeCount = cantSeeResponses.length;
    
    double maxBlur = 0;
    for (var r in correctResponses) {
      if (r.blurLevel > maxBlur) maxBlur = r.blurLevel;
    }
    
    List<String> suspectedConditions = [];
    String severity = 'normal';
    bool criticalAlert = false;
    
    // Pattern 1: NO LIGHT PERCEPTION (NLP)
    if (accuracy == 0 || (accuracy < 5 && cantSeeCount >= 8)) {
      suspectedConditions.add('No Light Perception (NLP)');
      suspectedConditions.add('Complete Optic Nerve Damage');
      suspectedConditions.add('Severe Retinal Detachment');
      suspectedConditions.add('End-stage Glaucoma');
      severity = 'CRITICAL';
      criticalAlert = true;
    }
    // Pattern 2: LIGHT PERCEPTION ONLY (LP)
    else if (accuracy < 10 && cantSeeCount >= 6) {
      suspectedConditions.add('Light Perception Only (LP)');
      suspectedConditions.add('Advanced Diabetic Retinopathy');
      suspectedConditions.add('Severe ARMD (Age-Related Macular Degeneration)');
      suspectedConditions.add('Advanced Retinitis Pigmentosa');
      severity = 'CRITICAL';
      criticalAlert = true;
    }
    // Pattern 3: HAND MOTION (HM) - Severe impairment
    else if (accuracy < 15 && cantSeeCount >= 5) {
      suspectedConditions.add('Hand Motion Vision (HM)');
      suspectedConditions.add('Proliferative Diabetic Retinopathy (PDR)');
      suspectedConditions.add('Vitreous Hemorrhage');
      suspectedConditions.add('Dense Cataract');
      suspectedConditions.add('Advanced ROP (Retinopathy of Prematurity)');
      severity = 'SEVERE';
      criticalAlert = true;
    }
    // Pattern 4: Counting Fingers - Very poor vision
    else if (accuracy < 25 && maxBlur < 0.5) {
      suspectedConditions.add('Counting Fingers Vision');
      suspectedConditions.add('Moderate to Severe Diabetic Retinopathy');
      suspectedConditions.add('Wet ARMD');
      suspectedConditions.add('Corneal Opacity/Scarring');
      severity = 'SEVERE';
      criticalAlert = false; // Can still attempt refraction
    }
    // Pattern 5: Very poor vision - suspect pathology
    else if (accuracy < 35 && cantSeeCount >= 4) {
      suspectedConditions.add('Severe Visual Impairment');
      suspectedConditions.add('High Myopia with complications');
      suspectedConditions.add('Diabetic Macular Edema');
      suspectedConditions.add('Geographic Atrophy (ARMD)');
      suspectedConditions.add('Moderate Retinitis Pigmentosa');
      severity = 'HIGH';
    }
    // Pattern 6: Poor central vision (possible macular disease)
    else if (accuracy < 50 && maxBlur < 1.0) {
      suspectedConditions.add('Macular Pathology Suspected');
      suspectedConditions.add('Early ARMD');
      suspectedConditions.add('Diabetic Maculopathy');
      suspectedConditions.add('Macular Hole');
      suspectedConditions.add('Central Serous Retinopathy');
      severity = 'MODERATE';
    }
    
    // Age-specific screening
    if (patientAge != null) {
      if (patientAge >= 50 && accuracy < 60) {
        suspectedConditions.add('Age-Related Macular Degeneration (ARMD)');
        suspectedConditions.add('Cataract');
      }
      if (patientAge >= 40 && accuracy < 50) {
        suspectedConditions.add('Diabetic Retinopathy (if diabetic)');
        suspectedConditions.add('Glaucoma');
      }
    }
    
    return {
      'critical_alert': criticalAlert,
      'severity': severity,
      'suspected_conditions': suspectedConditions,
      'accuracy': accuracy,
      'cant_see_count': cantSeeCount,
      'max_blur': maxBlur,
    };
  }
  
  // ═══════════════════════════════════════════════════════════
  // COMPREHENSIVE ANALYSIS
  // ═══════════════════════════════════════════════════════════
  
  static Map<String, dynamic> analyzeAccommodation(
    List<TestResponse> responses,
    int? patientAge,
  ) {
    if (responses.isEmpty) {
      return {
        'accommodating': false,
        'estimated_accommodation': 0.0,
        'interpretation': 'Insufficient data',
        'recommendation': 'Complete test first',
        'patient_type': 'unknown',
        'disease_screening': {},
      };
    }
    
    // Disease screening first
    final diseaseScreening = _screenForDiseases(responses, patientAge);
    
    final correctResponses = responses.where((r) => r.correct).toList();
    final cantSeeResponses = responses.where((r) => r.userDirection == 'cant_see').toList();
    
    double accuracy = (correctResponses.length / responses.length) * 100;
    double maxSuccessBlur = 0;
    
    for (var r in correctResponses) {
      if (r.blurLevel > maxSuccessBlur) maxSuccessBlur = r.blurLevel;
    }
    
    String patientType = 'unknown';
    String ageCategory = '';
    
    if (patientAge != null) {
      if (patientAge <= 25) {
        ageCategory = 'Young Adult';
      } else if (patientAge <= 40) {
        ageCategory = 'Adult';
      } else if (patientAge <= 45) {
        ageCategory = 'Early Presbyope';
      } else if (patientAge <= 55) {
        ageCategory = 'Presbyope';
      } else {
        ageCategory = 'Late Presbyope';
      }
    }
    
    // Check for critical pathology first
    if (diseaseScreening['critical_alert'] == true) {
      patientType = 'CRITICAL: ${diseaseScreening['severity']} Visual Impairment';
    } else if (accuracy >= 90.0 && maxSuccessBlur >= 4.0 && cantSeeResponses.isEmpty) {
      patientType = 'Likely Hyperope (with accommodation)';
    } else if (accuracy >= 85.0 && maxSuccessBlur >= 3.5) {
      patientType = 'Emmetrope or Mild Hyperope';
    } else if (accuracy >= 70.0 && maxSuccessBlur >= 2.0) {
      patientType = 'Mild to Moderate Myope';
    } else if (accuracy >= 50.0) {
      patientType = 'Moderate to High Myope';
    } else if (accuracy >= 30.0) {
      patientType = 'High Myope (>-6.00D)';
    } else if (accuracy >= 15.0) {
      patientType = 'Extreme Myope or Pathology Suspected';
    } else {
      patientType = 'Severe Visual Impairment - REFER URGENTLY';
    }
    
    // Astigmatism detection
    final validResponses = responses.where((r) => r.userDirection != 'cant_see').toList();
    final horizontalResponses = validResponses.where((r) => 
        r.direction == 'left' || r.direction == 'right').toList();
    final verticalResponses = validResponses.where((r) => 
        r.direction == 'up' || r.direction == 'down').toList();
    
    double horizontalAccuracy = horizontalResponses.isEmpty ? 100 
        : (horizontalResponses.where((r) => r.correct).length / horizontalResponses.length) * 100;
    double verticalAccuracy = verticalResponses.isEmpty ? 100 
        : (verticalResponses.where((r) => r.correct).length / verticalResponses.length) * 100;
    
    double accuracyDiff = (horizontalAccuracy - verticalAccuracy).abs();
    
    if (accuracyDiff >= 30) {
      patientType += ' with Significant Astigmatism';
    } else if (accuracyDiff >= 20) {
      patientType += ' with Moderate Astigmatism';
    } else if (accuracyDiff >= 10) {
      patientType += ' with Mild Astigmatism';
    }
    
    bool likelyAccommodating = false;
    double estimatedAccommodation = 0.0;
    String interpretation = '';
    String recommendation = '';
    
    // Critical pathology handling
    if (diseaseScreening['critical_alert'] == true) {
      interpretation = '⚠️ CRITICAL: Severe visual impairment detected. Possible conditions: ${(diseaseScreening['suspected_conditions'] as List).join(", ")}';
      recommendation = '🚨 URGENT REFERRAL TO OPHTHALMOLOGIST REQUIRED. Do not attempt refraction. Patient needs comprehensive eye examination, dilated fundus exam, OCT, and visual field testing.';
    } else if (diseaseScreening['severity'] == 'HIGH' || diseaseScreening['severity'] == 'SEVERE') {
      interpretation = '⚠️ Significant visual impairment detected. Possible pathology. Suspected: ${(diseaseScreening['suspected_conditions'] as List).join(", ")}';
      recommendation = 'REFER to ophthalmologist for comprehensive examination. May attempt refraction but expect poor best-corrected acuity. Fundus examination essential.';
    } else if (accuracy >= 90.0 && maxSuccessBlur >= 4.0 && cantSeeResponses.isEmpty) {
      likelyAccommodating = true;
      estimatedAccommodation = patientAge != null && patientAge <= 30 ? 2.00 : 
                              patientAge != null && patientAge <= 40 ? 1.50 :
                              patientAge != null && patientAge <= 50 ? 1.00 : 0.50;
      interpretation = 'High accommodation detected masking hyperopia.';
      recommendation = 'HYPEROPE: Start with calculated Rx + ${estimatedAccommodation.toStringAsFixed(2)}D. Consider cycloplegic refraction.';
    } else if (accuracy < 50 && cantSeeResponses.length >= 3) {
      interpretation = 'Poor vision despite correction attempt. High myopia or possible pathology.';
      recommendation = 'HIGH MYOPE: Use calculated Rx but verify with retinoscopy. Check for pathologic myopia. Dilated fundus exam recommended.';
    } else {
      interpretation = 'Refraction appears within normal limits.';
      recommendation = 'Proceed with standard subjective refraction refinement.';
    }
    
    if (patientAge != null && patientAge >= 40 && diseaseScreening['critical_alert'] != true) {
      recommendation += ' Add near correction (+1.00 to +2.50 ADD for presbyopia).';
    }
    
    return {
      'accommodating': likelyAccommodating,
      'estimated_accommodation': estimatedAccommodation,
      'interpretation': interpretation,
      'recommendation': recommendation,
      'patient_type': patientType,
      'age_category': ageCategory,
      'confidence': accuracy >= 90.0 ? 'High' : accuracy >= 70.0 ? 'Moderate' : accuracy >= 50.0 ? 'Low' : 'Very Low',
      'disease_screening': diseaseScreening,
    };
  }
}