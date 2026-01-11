class EyeResult {
  final String eye;
  final String sphere;
  final String cylinder;
  final int axis;
  final String accuracy;
  final String avgBlur;

  EyeResult({
    required this.eye,
    required this.sphere,
    required this.cylinder,
    required this.axis,
    required this.accuracy,
    required this.avgBlur,
  });

  Map<String, dynamic> toJson() {
    return {
      'eye': eye,
      'sphere': sphere,
      'cylinder': cylinder,
      'axis': axis,
      'accuracy': accuracy,
      'avgBlur': avgBlur,
    };
  }
}