import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/status_indicator.dart';
import '../services/face_detection_service.dart';
import '../services/distance_calculation_service.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({Key? key}) : super(key: key);

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  CameraController? _cameraController;
  FaceDetectionService? _faceDetectionService;
  bool _isProcessing = false;
  bool _faceDetected = false;
  double _distance = 0;
  bool _distanceValid = false;
  bool _cameraInitialized = false;
  
  // IPD tracking
  double _ipdCm = 0;
  bool _eyesDetected = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceDetectionService = FaceDetectionService();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _cameraInitialized = true;
        });
        _startImageStream();
      }
    } catch (e) {
       print('Camera initialization error: $e');
       // Show error to user
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Camera error: ${e.toString()}'),
             backgroundColor: Colors.red,
             duration: const Duration(seconds: 5),
           ),
         );
       }
    }
  }

  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessing || _faceDetectionService == null) return;

      _isProcessing = true;

      try {
        final result = await _faceDetectionService!.detectFaceAndDistance(image);
        
        if (mounted) {
          setState(() {
            _faceDetected = result['faceDetected'] as bool;
            _distance = result['distance'] as double;
            _distanceValid = result['distanceValid'] as bool;
            _ipdCm = result['ipdCm'] as double;
            _eyesDetected = result['eyesDetected'] as bool;
          });
        }
      } catch (e) {
        print('Face detection error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  @override
  void dispose() {
    _stopImageStream();
    _cameraController?.dispose();
    _faceDetectionService?.dispose();
    super.dispose();
  }

  Future<void> _stopImageStream() async {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
      } catch (e) {
        print('[CalibrationScreen] Error stopping image stream: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                'Distance Calibration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Position your face so the camera can detect you at 1 meter distance',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              if (_cameraController != null && _cameraInitialized)
                Expanded(
                  child: Stack(
                    children: [
                      CameraView(controller: _cameraController!),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          children: [
                            StatusIndicator(
                              status: _faceDetected,
                              message: _faceDetected 
                                  ? 'Face Detected' 
                                  : 'No Face Detected',
                              color: _faceDetected 
                                  ? const Color(0xFF10B981) 
                                  : const Color(0xFFEF4444),
                            ),
                            if (_faceDetected) ...[
                              const SizedBox(height: 8),
                              // IPD indicator
                              StatusIndicator(
                                status: _eyesDetected,
                                message: DistanceCalculationService.getIPDStatus(_ipdCm, _eyesDetected),
                                color: _eyesDetected 
                                    ? const Color(0xFF3B82F6)  // Blue
                                    : const Color(0xFFEF4444), // Red
                              ),
                              const SizedBox(height: 8),
                              // Distance indicator
                              StatusIndicator(
                                status: _distanceValid,
                                message: _eyesDetected 
                                    ? 'Distance: ${_distance.toInt()}cm${_distanceValid ? " ✓" : " (Target: 40cm ±15cm)"}'
                                    : 'Position eyes in view',
                                color: DistanceCalculationService.getFeedbackColor(_distance),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              if (_faceDetected && !_distanceValid)
                Text(
                  DistanceCalculationService.getDistanceFeedback(_distance),
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 16,
                  ),
                ),
              
              if (_distanceValid)
                const Text(
                  'Perfect distance! You\'re ready to begin.',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 16,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _distanceValid
                      ? () {
                          context.read<TestProvider>().setScreen('relaxation');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _distanceValid 
                        ? const Color(0xFF10B981) 
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _distanceValid 
                        ? 'Continue to Test' 
                        : 'Adjust Distance First',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}