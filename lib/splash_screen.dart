import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for 3 seconds while the animation plays
    await Future.delayed(const Duration(seconds: 3));

    // Navigate to the main screen and remove the splash screen from navigation history
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Change this to match your animation's background
      body: Center(
        child: Lottie.asset(
          'assets/splash_animation.json', // Your animation path
          width: 250,
          height: 250,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
