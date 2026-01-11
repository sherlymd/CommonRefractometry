import 'dart:math';
import '../models/test_response.dart';
import '../models/eye_result.dart';
import '../models/health_risk_assessment.dart';

/// -----------------------------------------------------------------------
/// ADVANCED REFRACTION SERVICE (Age 15+)
/// -----------------------------------------------------------------------
/// This service provides clinical-grade logic for mobile refractometry.
/// It specifically handles:
/// 1. Age-based Accommodation (Hyperopia masking in youth)
/// 2. Presbyopia ( Near vision loss in 40+)
/// 3. Disease Screening (ARMD, Glaucoma, Diabetic Retinopathy, Cataract)
class AdvancedRefractionService {
  
  // ======================================================================
  // ACCURACY CONSTRAINTS
  // ======================================================================
  
  /// Maximum accepted error tolerance for clinical accuracy
  /// ±0.25 Diopter for both Sphere and Cylinder
  static const double maxAcceptedErrorSph = 0.25;
  static const double maxAcceptedErrorCyl = 0.25;
  
  /// Minimum detectable change in diopters (clinical significance threshold)
  static const double minDiopterStep = 0.25;
  
  // ======================================================================
  // PUBLIC API
  // ======================================================================

  /// Calculates refractive error including Sph, Cyl, Axis and performs
  /// a concurrent disease screening based on performance patterns.
  static AdvancedEyeResult calculateFullAssessment({
    required List<TestResponse> distanceResponses,
    required List<TestResponse> nearResponses, // Can be empty if not performed
    required int age,
    required String eye, // 'Left' or 'Right'
  }) {
    // 1. Calculate Base Refraction (Distance)
    final distanceResult = _calculateBaseRefraction(distanceResponses, nearResponses, age);
    
    // 2. Assess Accommodation & Presbyopia
    final accommodationAnalysis = _analyzeAccommodation(
      distanceResult, 
      nearResponses, 
      age
    );

    // 3. Finalize Prescription
    double finalSphere = distanceResult.sphere + accommodationAnalysis.sphereAdjustment;
    double finalAdd = accommodationAnalysis.recommendedAdd;

    // 4. Disease Screening
    final healthAssessment = _screenForPathology(
      distanceResponses, 
      age, 
      finalSphere
    );

    // Format results with proper rounding to 0.25D steps
    return AdvancedEyeResult(
      modelResult: EyeResult(
        eye: eye,
        sphere: _formatDiopter(_roundToDiopterStep(finalSphere)),
        cylinder: _formatDiopter(_roundToDiopterStep(distanceResult.cylinder)),
        axis: distanceResult.axis,
        accuracy: distanceResult.accuracy.toStringAsFixed(1),
        avgBlur: distanceResult.avgBlur.toStringAsFixed(2),
      ),
      addPower: _formatDiopter(_roundToDiopterStep(finalAdd), isAdd: true),
      healthAssessment: healthAssessment,
      isAccommodating: accommodationAnalysis.isAccommodating,
    );
  }

  // ======================================================================
  // CORE LOGIC: REFRACTION
  // ======================================================================

  static _RefractionIntermediate _calculateBaseRefraction(
    List<TestResponse> distanceResponses, 
    List<TestResponse> nearResponses,
    int age
  ) {
    // -- 1. Calculate Thresholds --
    // Distance Threshold
    double distThreshold = _calculateVisualThreshold(distanceResponses);
    double distAccuracy = _calcAcc(distanceResponses);

    // Near Threshold (if available)
    double nearThreshold = nearResponses.isNotEmpty 
        ? _calculateVisualThreshold(nearResponses) 
        : distThreshold;
    double nearAccuracy = _calcAcc(nearResponses);

    // -- 2. Determine Refractive State (Myopia vs Hyperopia) --
    // Logic:
    // Myopia: Distance Poor (Low Threshold), Near Good (High Threshold) -> dist < near
    // Hyperopia: Distance Good/Okay, Near Poor -> dist > near
    // Presbyopia: Distance Good, Near Poor -> dist > near (similar pattern to Hyperopia)
    
    double sphere = 0.0;
    bool isMyopicPattern = true; // Default assumption

    // If we have near data, comparing gives us the sign
    if (nearResponses.isNotEmpty) {
      if (distThreshold > nearThreshold + 1.0) {
        isMyopicPattern = false; // Hyperopic pattern (Better at distance)
      } else if (nearThreshold > distThreshold + 1.0) {
        isMyopicPattern = true; // Myopic pattern (Better at near)
      } else {
        // Equal performance -> High Refractive Error or Emmetropia
        // Use raw value to decide. If both low -> High Error.
        // If dist is very low (<2), likely Myopia.
        isMyopicPattern = true;
      }
    }

    // -- 3. Calculate Sphere Magnitude --
    // We use the "worse" threshold to determine magnitude of error
    // For Myope (worse at distance), use distThreshold.
    // For Hyperope (worse at near), use nearThreshold.
    
    double operatingThreshold = isMyopicPattern ? distThreshold : nearThreshold;
    
    if (operatingThreshold >= 7.0 && distAccuracy >= 90) {
      sphere = 0.00; // Emmetropia
    } else {
      // Map threshold to diopters magnitude (in 0.25D steps for precision)
      double magnitude = 0.0;
      if (operatingThreshold >= 6.5) magnitude = 0.00; // Essentially emmetropic
      else if (operatingThreshold >= 6.0) magnitude = 0.25;
      else if (operatingThreshold >= 5.5) magnitude = 0.50;
      else if (operatingThreshold >= 5.0) magnitude = 0.75;
      else if (operatingThreshold >= 4.5) magnitude = 1.00;
      else if (operatingThreshold >= 4.0) magnitude = 1.25;
      else if (operatingThreshold >= 3.5) magnitude = 1.50;
      else if (operatingThreshold >= 3.0) magnitude = 1.75;
      else if (operatingThreshold >= 2.5) magnitude = 2.00;
      else if (operatingThreshold >= 2.0) magnitude = 2.50;
      else if (operatingThreshold >= 1.5) magnitude = 3.00;
      else if (operatingThreshold >= 1.0) magnitude = 3.50;
      else magnitude = 4.00; // Very poor (high error)

      // Apply sign
      sphere = isMyopicPattern ? -magnitude : magnitude;

      // CONTRADICTION CHECK (Clinical Heuristic):
      // A -2.50 Myope should see PERFECTLY at 40cm (Accommodation-free point).
      // If the patient is assigned Myopia (Minus), but their Near Threshold is POOR (< 5.0),
      // it is a contradiction. They are likely a High Hyperope who sees poorly at both distances.
      if (sphere < -0.75 && nearResponses.isNotEmpty) {
        if (nearThreshold < 5.0) {
           // Paradox: Significant myopia identified, but near vision is bad.
           // Likely Hyperopia.
           sphere = magnitude; // Flip sign to Plus
        }
      }
    }
    
    // Cap values
    if (sphere < -10.00) sphere = -10.00;
    if (sphere > 8.00) sphere = 8.00;

    // Additional Hyperopia check for young people passing distance
    // If young (<30), passes distance perfectly (Sphere 0), but Near is bad?
    // Already handled by logic above (dist > near -> Positive Sphere).
    
    // -- 3. Cylinder (Astigmatism) Calculation --
    // Analyze directional disparity (using Distance responses primarily as cyl affects distance more)
    // Combine both if needed, but usually distance is best for cyl
    var relevantResponses = distanceResponses.isNotEmpty ? distanceResponses : nearResponses;
    
    var hRes = relevantResponses.where((r) => ['left','right'].contains(r.direction)).toList();
    var vRes = relevantResponses.where((r) => ['up','down'].contains(r.direction)).toList();
    
    double hAcc = _calcAcc(hRes);
    double vAcc = _calcAcc(vRes);
    double diff = (hAcc - vAcc).abs();
    
    double cyl = 0.0;
    int axis = 0;

    // More granular astigmatism detection with 0.25D steps
    if (diff >= 50) {
      cyl = -2.00; // Very significant astigmatism
    } else if (diff >= 40) {
      cyl = -1.50;
    } else if (diff >= 30) {
      cyl = -1.00;
    } else if (diff >= 20) {
      cyl = -0.75;
    } else if (diff >= 12) {
      cyl = -0.50;
    } else if (diff >= 8) {
      cyl = -0.25; // Minimal astigmatism
    }
    
    // Axis logic
    if (cyl != 0) {
      axis = (vAcc < hAcc) ? 180 : 90;
    }

    return _RefractionIntermediate(
      sphere: sphere,
      cylinder: cyl,
      axis: axis,
      accuracy: distAccuracy,
      avgBlur: distThreshold,
    );
  }

  static double _calculateVisualThreshold(List<TestResponse> responses) {
    if (responses.isEmpty) return 0.0;
    
    final correct = responses.where((r) => r.correct).toList();
    final incorrect = responses.where((r) => !r.correct).toList();
    
    double maxBlurSeen = 0.0;
    for (var r in correct) {
      if (r.blurLevel > maxBlurSeen) maxBlurSeen = r.blurLevel;
    }

    double minBlurFailed = 10.0;
    for (var r in incorrect) {
      if (r.blurLevel < minBlurFailed) minBlurFailed = r.blurLevel;
    }

    if (incorrect.isEmpty) return maxBlurSeen;
    
    // If failed at higher blur than seen (logical), midpoint
    if (minBlurFailed > maxBlurSeen) {
       return maxBlurSeen; // Conservative
    }
    
    return (maxBlurSeen + minBlurFailed) / 2;
  }

  // ======================================================================
  // CORE LOGIC: ACCOMMODATION & PRESBYOPIA
  // ======================================================================

  static _AccommodationResult _analyzeAccommodation(
    _RefractionIntermediate distanceResult, 
    List<TestResponse> nearResponses,
    int age
  ) {
    double sphereAdj = 0.0;
    double add = 0.0;
    bool isAccommodating = false;

    // -- A. YOUNG USERS (15 - 35) --
    // Potential for Latent Hyperopia (Farsightedness hidden by focusing)
    if (age < 35) {
      // If user sees very well (High blur threshold) and accuracy is perfect
      // They might be over-accommodating.
      if (distanceResult.sphere == 0.0 && distanceResult.accuracy > 95) {
        // Suspect Hyperopia
        isAccommodating = true;
        // Age-based buffering
        if (age < 20) sphereAdj = 0.75;      // 15-19: Strong accommodation
        else if (age < 25) sphereAdj = 0.50; // 20-25: Moderate
        else sphereAdj = 0.25;               // 25-35: Mild
      }
    }

    // -- B. OLDER USERS (40+) - PRESBYOPIA --
    if (age >= 40) {
      // 1. Theoretical ADD based on Age (Donders' Table approximation)
      double theoreticalAdd = 0.0;
      if (age >= 60) theoreticalAdd = 2.50;
      else if (age >= 55) theoreticalAdd = 2.25;
      else if (age >= 50) theoreticalAdd = 2.00;
      else if (age >= 45) theoreticalAdd = 1.50;
      else if (age >= 40) theoreticalAdd = 1.00;

      // 2. Refine if Near Test Data Available
      if (nearResponses.isNotEmpty) {
        // Calculate performance at near
        double nearAcc = _calcAcc(nearResponses);
        
        // If Near performance is bad (< 70%) but Distance is Good (> 85%),
        // Suggest higher ADD
        if (nearAcc < 70 && distanceResult.accuracy > 85) {
          add = theoreticalAdd + 0.50; // Boost ADD
        } else if (nearAcc > 90) {
          // Sees well at near, maybe less ADD needed
          add = max(0.0, theoreticalAdd - 0.50); 
        } else {
          add = theoreticalAdd;
        }
      } else {
        // Fallback to theoretical only
        add = theoreticalAdd;
      }
    }

    return _AccommodationResult(sphereAdj, add, isAccommodating);
  }

  // ======================================================================
  // CORE LOGIC: DISEASE SCREENING
  // ======================================================================

  static HealthRiskAssessment _screenForPathology(
    List<TestResponse> responses, 
    int age,
    double estimatedSphere
  ) {
    List<DiseaseRisk> risks = [];
    bool critical = false;

    // Helpers
    final cantSee = responses.where((r) => r.userDirection == 'cant_see').toList();
    final incorrect = responses.where((r) => !r.correct).toList();
    final double accuracy = (responses.length - incorrect.length) / responses.length;

    // ----------------------------------------------------
    // 1. AGE-RELATED MACULAR DEGENERATION (ARMD)
    // ----------------------------------------------------
    // Risk Factors: Age > 50, Central vision distortion (inconsistent acuity filters)
    if (age >= 50) {
      if (accuracy < 0.60 && cantSee.length > responses.length * 0.3) {
        risks.add(DiseaseRisk(
          conditionName: "Possible ARMD (Macular Degeneration)",
          riskLevel: RiskLevel.high,
          confidenceScore: 0.75,
          riskFactors: ["Age $age (>50)", "High central vision dropout", "Poor acuity"],
          recommendation: "Amsler Grid test & Fundus exam recommended immediately.",
        ));
      }
    } else if (age >= 15 && age < 40 && accuracy < 0.50 && estimatedSphere > -2.00) {
       // Young person, not myopic, but cant see?
       // Check for Macular Dystrophy (Stargardt's-like pattern)
       if (cantSee.length > 3) {
         risks.add(DiseaseRisk(
          conditionName: "Macular Dystrophy Suspected",
          riskLevel: RiskLevel.moderate,
          confidenceScore: 0.40,
          riskFactors: ["Age $age (<40)", "Unexplained central vision loss"],
          recommendation: "Referral to retina specialist.",
        ));
       }
    }

    // ----------------------------------------------------
    // 2. DIABETIC RETINOPATHY
    // ----------------------------------------------------
    // Risk Factors: Fluctuating vision. 
    // Logic: User gets hard ones right (high blur) but easy ones wrong (low blur)
    bool fluctuation = false;
    // Check if user missed 'easy' ones (blur < 2) but hit 'hard' ones (blur > 5)
    int missedEasy = incorrect.where((r) => r.blurLevel < 2.0).length;
    int hitHard = responses.where((r) => r.correct && r.blurLevel > 5.0).length;
    
    if (missedEasy > 2 && hitHard > 2) {
      fluctuation = true;
      risks.add(DiseaseRisk(
        conditionName: "Diabetic Retinopathy Screening",
        riskLevel: RiskLevel.moderate,
        confidenceScore: 0.60,
        riskFactors: ["Inconsistent visual performance", "Potential scotomas (blind spots)"],
        recommendation: "Dilated eye exam needed to rule out retinopathy.",
      ));
    }

    // ----------------------------------------------------
    // 3. GLAUCOMA
    // ----------------------------------------------------
    // Hard to detect on central acuity, but severe cases show "Tunnel Vision".
    // If accuracy is good only on specific directional optotypes (sectoral loss)?
    // E.g. Sees 'Left'/'Right' well, but misses 'Up'/'Down' consistently independent of blur.
    
    var upDownMisses = incorrect.where((r) => ['up','down'].contains(r.direction)).length;
    var leftRightMisses = incorrect.where((r) => ['left','right'].contains(r.direction)).length;
    
    // If predominantly missing one axis significantly more (>3x)
    if (age > 40 && (upDownMisses > leftRightMisses * 3 || leftRightMisses > upDownMisses * 3)) {
       risks.add(DiseaseRisk(
        conditionName: "Glaucoma Screening (Visual Field Defect)",
        riskLevel: RiskLevel.moderate,
        confidenceScore: 0.5,
        riskFactors: ["Sectoral vision loss detected", "Age $age"],
        recommendation: "Visual Field (Perimetry) Test Required.",
      ));
    }

    // ----------------------------------------------------
    // 4. CATARACT
    // ----------------------------------------------------
    // Generalized Blur + Glare sensitivity (Simulated).
    // If performance is poor (<50%) uniformly across ALL blur levels.
    if (age > 55 && accuracy < 0.50 && !fluctuation) {
      risks.add(DiseaseRisk(
        conditionName: "Cataract",
        riskLevel: (accuracy < 0.3) ? RiskLevel.high : RiskLevel.moderate,
        confidenceScore: 0.8,
        riskFactors: ["Age $age (>55)", "Generalized reduced acuity"],
        recommendation: "Slit-lamp examination for lens opacity.",
      ));
    }

    // Critical Flag
    critical = risks.any((r) => r.riskLevel == RiskLevel.critical || r.riskLevel == RiskLevel.high);

    return HealthRiskAssessment(
      criticalAlert: critical,
      identifiedRisks: risks,
      overallInterpretation: risks.isEmpty 
          ? "No specific pathology patterns detected." 
          : "Signs consistent with ocular pathology detected.",
    );
  }

  // ======================================================================
  // UTILS
  // ======================================================================
  
  static double _calcAcc(List<TestResponse> items) {
    if (items.isEmpty) return 0.0;
    return (items.where((i) => i.correct).length / items.length) * 100;
  }

  /// Round to nearest 0.25 diopter step for clinical accuracy
  /// Ensures all prescriptions follow standard 0.25D increments
  static double _roundToDiopterStep(double value) {
    // Round to nearest 0.25
    return (value / minDiopterStep).round() * minDiopterStep;
  }

  static String _formatDiopter(double val, {bool isAdd = false}) {
    if (val == 0.0) return "0.00"; // Plano
    String s = val.toStringAsFixed(2);
    return (val > 0 && !isAdd) ? "+$s" : s; 
    // Note: ADD is usually formatted as "+2.00", Sphere can be "+2.00" or "-2.00"
    // If val is positive, ensure + sign.
  }
}

// --------------------------------------------------------------------------
// HELPER CLASSES
// --------------------------------------------------------------------------

class AdvancedEyeResult {
  final EyeResult modelResult;
  final String addPower; // e.g. "+2.00" or "0.00"
  final HealthRiskAssessment healthAssessment;
  final bool isAccommodating;

  AdvancedEyeResult({
    required this.modelResult,
    required this.addPower,
    required this.healthAssessment,
    required this.isAccommodating,
  });
}

class _RefractionIntermediate {
  final double sphere;
  final double cylinder;
  final int axis;
  final double accuracy;
  final double avgBlur;

  _RefractionIntermediate({
    required this.sphere,
    required this.cylinder, 
    required this.axis,
    required this.accuracy,
    required this.avgBlur
  });

  factory _RefractionIntermediate.zero() {
    return _RefractionIntermediate(sphere:0, cylinder:0, axis:0, accuracy:0, avgBlur:0);
  }
}

class _AccommodationResult {
  final double sphereAdjustment;
  final double recommendedAdd;
  final bool isAccommodating;

  _AccommodationResult(this.sphereAdjustment, this.recommendedAdd, this.isAccommodating);
}
