import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school,
                      color: Colors.blue.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Instructions',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'How to take the vision test',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Introduction
                    _buildSectionCard(
                      icon: Icons.info_outline,
                      iconColor: Colors.blue,
                      title: 'What You\'ll See',
                      child: const Text(
                        'During the test, you\'ll see the letter "E" pointing in different directions. '
                        'The letter will get smaller and may become blurry as the test progresses.',
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Visual Examples
                    _buildSectionCard(
                      icon: Icons.visibility,
                      iconColor: Colors.green,
                      title: 'Image Clarity Levels',
                      child: Column(
                        children: [
                          _buildClarityExample(
                            'Sharp & Clear',
                            'The "E" is easy to see with sharp edges',
                            Icons.check_circle,
                            Colors.green,
                            'E',
                            0.0,
                          ),
                          const SizedBox(height: 12),
                          _buildClarityExample(
                            'Slightly Blurred',
                            'The "E" edges are a bit soft but still readable',
                            Icons.info,
                            Colors.orange,
                            'E',
                            1.0,
                          ),
                          const SizedBox(height: 12),
                          _buildClarityExample(
                            'Very Blurry/Distorted',
                            'Hard to make out the direction clearly',
                            Icons.warning,
                            Colors.red,
                            'E',
                            3.0,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // How to Respond
                    _buildSectionCard(
                      icon: Icons.touch_app,
                      iconColor: Colors.purple,
                      title: 'How to Respond',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResponseGuide(
                            'For Sharp or Slightly Blurred Images',
                            'Tap the direction button: UP, DOWN, LEFT, or RIGHT',
                            Icons.arrow_upward,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _buildResponseGuide(
                            'For Very Blurry or Distorted Images',
                            'Tap "Not Clear / Can\'t See" button',
                            Icons.visibility_off,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Important Tips
                    _buildSectionCard(
                      icon: Icons.lightbulb_outline,
                      iconColor: Colors.amber,
                      title: 'Important Tips',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTipItem('Follow the distance instructions carefully'),
                          _buildTipItem('Take your time - there\'s no rush'),
                          _buildTipItem('Be honest - wrong answers help us measure accurately'),
                          _buildTipItem('The test works for both eyes separately'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Ready Button
                    ElevatedButton(
                      onPressed: () {
                        final provider = Provider.of<TestProvider>(context, listen: false);
                        provider.setScreen('calibration');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'I\'m Ready to Start',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward, size: 24),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Back Button
                    TextButton(
                      onPressed: () {
                        final provider = Provider.of<TestProvider>(context, listen: false);
                        provider.setScreen('welcome');
                      },
                      child: Text(
                        'Back to Welcome',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildClarityExample(
    String title,
    String description,
    IconData statusIcon,
    Color statusColor,
    String letter,
    double blurSigma,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          // Visual Example
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  color: Colors.black,
                  shadows: blurSigma > 0
                      ? [
                          Shadow(
                            blurRadius: blurSigma * 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseGuide(
    String condition,
    String action,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  condition,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
