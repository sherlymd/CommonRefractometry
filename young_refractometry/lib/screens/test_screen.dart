import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../providers/test_provider.dart';
import '../models/test_config.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showDistanceChange = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TestProvider>(context, listen: false).startRound();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleResponse(String direction) {
    final provider = Provider.of<TestProvider>(context, listen: false);
    
    // Check if next round will change test type (distance to near or vice versa)
    final currentRound = TestConfig.getTestRoundConfiguration(
      provider.round,
      provider.patientAge,
    );
    final nextRound = TestConfig.getTestRoundConfiguration(
      provider.round + 1,
      provider.patientAge,
    );
    
    final isComplete = provider.handleResponse(direction);
    
    if (isComplete) {
      provider.completeEyeTest();
    } else {
      // Show distance change notification if switching between distance/near
      if (currentRound.testType != nextRound.testType) {
        setState(() => _showDistanceChange = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showDistanceChange = false);
          }
        });
      }
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _handleCantSee() {
    final provider = Provider.of<TestProvider>(context, listen: false);
    final isComplete = provider.handleCantSeeResponse();
    
    if (isComplete) {
      provider.completeEyeTest();
    } else {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TestProvider>(
      builder: (context, provider, child) {
        final testRound = TestConfig.getTestRoundConfiguration(
          provider.round,
          provider.patientAge,
        );
        
        final fontSize = TestConfig.getAdjustedFontSize(
          provider.round,
          provider.patientAge,
          provider.blurLevel,
        );
        
        final visionNotation = TestConfig.getVisionNotation(
          testRound.fontSize,
          testRound.testType,
        );
        
        final isNearVision = testRound.testType == TestType.near;
        
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Header
                    _buildHeader(provider, testRound, visionNotation, isNearVision),
                    
                    // Main test area
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            // Distance instruction card - PROMINENT
                            Expanded(
                              flex: 2,
                              child: _buildDistanceInstructionCard(isNearVision),
                            ),
                            
                            // Tumbling E - FIXED VERSION
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _scaleAnimation.value,
                                      child: Opacity(
                                        opacity: _fadeAnimation.value,
                                        child: _buildTumblingE(
                                          provider.direction,
                                          fontSize,
                                          provider.blurLevel,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            // Info bar
                            Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Text(
                                    'Size: ${fontSize.toInt()}px • Blur: ${provider.blurLevel.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Control panel
                    _buildControlPanel(),
                  ],
                ),
                
                // Distance change notification overlay
                if (_showDistanceChange)
                  _buildDistanceChangeOverlay(isNearVision),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(dynamic provider, TestRound testRound, String visionNotation, bool isNearVision) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            provider.currentEye == 'right' 
                                ? Icons.visibility 
                                : Icons.visibility_outlined,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.currentEye == 'right' 
                                ? 'Right Eye (OD)' 
                                : 'Left Eye (OS)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Round ${provider.round}/${TestConfig.maxRounds}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: provider.round / TestConfig.maxRounds,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          testRound.getTypeColor(),
                        ),
                        strokeWidth: 6,
                      ),
                      Text(
                        '${((provider.round / TestConfig.maxRounds) * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Test type banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isNearVision 
                    ? [Colors.orange.shade400, Colors.orange.shade600]
                    : [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(testRound.getTypeIcon(), color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  testRound.getTypeLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Vision notation
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: isNearVision ? Colors.orange.shade50 : Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNearVision 
                          ? Colors.orange.shade300 
                          : Colors.blue.shade300,
                    ),
                  ),
                  child: Text(
                    visionNotation,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isNearVision 
                          ? Colors.orange.shade900 
                          : Colors.blue.shade900,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 20)),
                const SizedBox(width: 12),
                Text(
                  testRound.difficulty,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceInstructionCard(bool isNearVision) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNearVision 
              ? [Colors.orange.shade50, Colors.orange.shade100]
              : [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNearVision ? Colors.orange.shade300 : Colors.blue.shade300,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: (isNearVision ? Colors.orange : Colors.blue).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              isNearVision ? Icons.phone_android : Icons.front_hand,
              size: 48,
              color: isNearVision ? Colors.orange.shade700 : Colors.blue.shade700,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Main instruction
          Text(
            isNearVision 
                ? '📖 READING DISTANCE' 
                : '📍 ARM\'S LENGTH',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isNearVision ? Colors.orange.shade900 : Colors.blue.shade900,
              letterSpacing: 1,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Distance measurement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isNearVision ? Colors.orange.shade400 : Colors.blue.shade400,
                width: 2,
              ),
            ),
            child: Text(
              isNearVision ? '40 cm (16 inches)' : '60 cm (24 inches)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isNearVision ? Colors.orange.shade800 : Colors.blue.shade800,
                fontFamily: 'Courier',
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Detailed instruction
          Text(
            isNearVision 
                ? 'Hold phone as if reading a book or menu\nComfortable reading position'
                : 'Extend your arm fully\nPhone at eye level',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isNearVision ? Colors.orange.shade800 : Colors.blue.shade800,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Visual representation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  size: 32,
                  color: Colors.grey.shade700,
                ),
                SizedBox(
                  width: isNearVision ? 30 : 60,
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color: isNearVision ? Colors.orange : Colors.blue,
                    ),
                  ),
                ),
                Icon(
                  Icons.phone_android,
                  size: isNearVision ? 28 : 24,
                  color: isNearVision ? Colors.orange.shade700 : Colors.blue.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTumblingE(String direction, double fontSize, double blurLevel) {
    double rotation = 0;
    switch (direction) {
      case 'up':
        rotation = -90 * 3.14159 / 180;
        break;
      case 'down':
        rotation = 90 * 3.14159 / 180;
        break;
      case 'left':
        rotation = 180 * 3.14159 / 180;
        break;
      case 'right':
        rotation = 0;
        break;
    }

    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.7, // 70% of screen width for more room
      height: screenWidth * 0.7, // Square container
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: rotation,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: blurLevel * 0.8,
            sigmaY: blurLevel * 0.8,
          ),
          child: Text(
            'E',
            style: TextStyle(
              fontSize: fontSize, // Use dynamic size
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 0,
              height: null, // Let font metrics decide
              fontFamily: 'monospace',
            ),
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Which direction is the E pointing?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          
          // Helper text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Say direction if sharp or slightly blurred',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Column(
            children: [
              _buildDirectionButton(Icons.arrow_upward, 'UP', () => _handleResponse('up')),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _buildDirectionButton(Icons.arrow_back, 'LEFT', () => _handleResponse('left'))),
                  const SizedBox(width: 20),
                  Expanded(child: _buildDirectionButton(Icons.arrow_forward, 'RIGHT', () => _handleResponse('right'))),
                ],
              ),
              const SizedBox(height: 10),
              _buildDirectionButton(Icons.arrow_downward, 'DOWN', () => _handleResponse('down')),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.visibility_off, size: 20),
              label: const Text(
                'Not Clear / Can\'t See',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.red.shade300, width: 2),
                foregroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _handleCantSee,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(IconData icon, String label, VoidCallback onPressed) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade500, Colors.blue.shade700],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceChangeOverlay(bool isNearVision) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(30),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isNearVision ? Colors.orange : Colors.blue).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNearVision ? Icons.arrow_forward : Icons.arrow_back,
                  size: 64,
                  color: isNearVision ? Colors.orange.shade700 : Colors.blue.shade700,
                ),
                const SizedBox(height: 20),
                Text(
                  isNearVision ? 'SWITCHING TO NEAR VISION' : 'SWITCHING TO DISTANCE VISION',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isNearVision ? Colors.orange.shade900 : Colors.blue.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isNearVision ? Colors.orange.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isNearVision ? Icons.phone_android : Icons.front_hand,
                        size: 48,
                        color: isNearVision ? Colors.orange.shade700 : Colors.blue.shade700,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isNearVision 
                            ? 'Move phone to READING DISTANCE\n40 cm (16 inches)'
                            : 'Hold phone at ARM\'S LENGTH\n60 cm (24 inches)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isNearVision ? Colors.orange.shade900 : Colors.blue.shade900,
                          height: 1.5,
                          fontFamily: 'Courier',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  final Color color;
  
  DashedLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}