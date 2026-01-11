import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:young_refractometry/utils/colors.dart';
import '../providers/test_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _ageController = TextEditingController();
  bool _showInstructions = false;
  
  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _showDistanceInstructions() {
    setState(() => _showInstructions = true);
  }

  void _startTest() {
    final provider = Provider.of<TestProvider>(context, listen: false);
    int? age = int.tryParse(_ageController.text);
    provider.setPatientAge(age);
    provider.setScreen('calibration');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showInstructions 
            ? _buildInstructionsScreen() 
            : _buildWelcomeContent(),
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.remove_red_eye,
              size: 80,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Mobile Refractometry',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Professional Eye Prescription Testing',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Age input
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Your Age',
              hintText: 'Enter your age in years',
              prefixIcon: const Icon(Icons.person, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.blue.shade50,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Age helps us detect presbyopia (age-related near vision loss)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // What you'll need section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.checklist, color: Colors.blue.shade700, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'What You\'ll Need',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRequirementItem(
                  Icons.light_mode,
                  'Good lighting',
                  'Well-lit room, avoid glare',
                ),
                _buildRequirementItem(
                  Icons.phone_android,
                  'Steady phone position',
                  'Hold firmly at specified distance',
                ),
                _buildRequirementItem(
                  Icons.timer,
                  '5-10 minutes',
                  'Complete test for both eyes',
                ),
                _buildRequirementItem(
                  Icons.straighten,
                  'TWO testing distances',
                  'Arm\'s length AND reading distance',
                  highlight: true,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Instructions button
          OutlinedButton.icon(
            onPressed: _showDistanceInstructions,
            icon: const Icon(Icons.help_outline, size: 24),
            label: const Text(
              'How Testing Distances Work',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.blue.shade300, width: 2),
              foregroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Start button
          ElevatedButton(
            onPressed: _startTest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: const Text(
              'Start Eye Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Age is recommended for accurate presbyopia detection',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String title, String description, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: highlight ? Colors.orange.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: highlight ? Colors.orange.shade700 : Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: highlight ? Colors.orange.shade900 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showInstructions = false),
              ),
              const Expanded(
                child: Text(
                  'Testing Distances',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Introduction
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Why Two Distances?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'To properly test your vision, we need TWO different distances:\n\n'
                  '• Distance vision (far): Tests myopia, hyperopia, astigmatism\n'
                  '• Near vision (reading): Tests presbyopia (age 40+)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Distance Vision Card
          _buildDistanceCard(
            title: '📍 DISTANCE VISION',
            subtitle: 'Testing far vision',
            distance: '60 cm (24 inches)',
            instruction: 'Hold phone at ARM\'S LENGTH',
            details: [
              'Extend your arm fully',
              'Phone at eye level',
              'Keep position steady',
              'Tests distance refractive error',
            ],
            color: Colors.blue,
            icon: Icons.front_hand,
          ),
          
          const SizedBox(height: 24),
          
          // Near Vision Card
          _buildDistanceCard(
            title: '📖 NEAR VISION',
            subtitle: 'Testing reading ability',
            distance: '40 cm (16 inches)',
            instruction: 'Hold phone at READING DISTANCE',
            details: [
              'As if reading a book',
              'Comfortable position',
              'Natural reading distance',
              'Tests presbyopia (age-related)',
            ],
            color: Colors.orange,
            icon: Icons.menu_book,
          ),
          
          const SizedBox(height: 32),
          
          // When you'll switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'When Do I Switch?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Don\'t worry! The app will tell you when to change distance.\n\n'
                  'You\'ll see a clear notification:\n'
                  '• "SWITCHING TO NEAR VISION - Move phone closer"\n'
                  '• "SWITCHING TO DISTANCE VISION - Extend arm"\n\n'
                  'Just follow the on-screen instructions!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Back button
          ElevatedButton(
            onPressed: () => setState(() => _showInstructions = false),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Got It!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard({
    required String title,
    required String subtitle,
    required String distance,
    required String instruction,
    required List<String> details,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.shade50, AppColors.primary.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.primary.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary.shade900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Distance badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.primary.shade400, width: 2),
            ),
            child: Text(
              distance,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary.shade800,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Main instruction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Details
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 18, color: AppColors.primary.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detail,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.shade900,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}