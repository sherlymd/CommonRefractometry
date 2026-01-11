import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/test_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/calibration_screen.dart';
import 'screens/relaxation_screen.dart';
import 'screens/test_screen.dart';
import 'screens/switch_eye_screen.dart';
import 'screens/results_screen.dart';
import 'screens/calibration_adjustment_screen.dart'; // Add this import
import 'screens/instruction_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set portrait orientation only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TestProvider(),
      child: MaterialApp(
        title: 'Young Refractometry',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TestProvider>(
      builder: (context, provider, child) {
        switch (provider.currentScreen) {
          case 'welcome':
            return const WelcomeScreen();
          case 'instruction':
            return const InstructionScreen();
          case 'calibration':
            return const CalibrationScreen();
          case 'relaxation':
            return const RelaxationScreen();
          case 'test':
            return const TestScreen();
          case 'switch':
            return const SwitchEyeScreen();
          case 'results':
            return const ResultsScreen();
          default:
            return const WelcomeScreen();
        }
      },
    );
  }
}

// Add this as a separate screen for settings/menu
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text(
              'Calibration Settings',
              style: TextStyle(fontFamily: 'Monospace'),
            ),
            subtitle: const Text(
              'Adjust clinical accuracy',
              style: TextStyle(fontFamily: 'Monospace'),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalibrationAdjustmentScreen(),
                ),
              );
            },
          ),
          // Add more settings options here
        ],
      ),
    );
  }
}