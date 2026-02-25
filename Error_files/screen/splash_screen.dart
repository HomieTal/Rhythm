import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Rhythm/screen/home_screen.dart';
import 'package:Rhythm/screen/welcome_screen.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      // Wait for 2 seconds with timeout protection
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Check if onboarding is completed with timeout
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⚠️ SharedPreferences timeout - using defaults');
          throw TimeoutException('SharedPreferences timed out');
        },
      );

      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (!mounted) return;

      // Navigate with error handling
      await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return onboardingCompleted ? const RhythmHome() : const WelcomeScreen();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Navigation error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Fallback navigation directly to home screen
      if (mounted) {
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RhythmHome()),
            );
          }
        } catch (e2) {
          debugPrint('Second navigation attempt failed: $e2');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/images/app_icon.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'Rhythm',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              'Ad-Free Music Player',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            // Developer credit
            Text(
              'By Drizzle Delighter',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


