// Import necessary packages
import 'dart:async'; // For using Timer
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:google_fonts/google_fonts.dart'; // Google Fonts
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase Auth

// Splash screen shown on app startup
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final supabase = Supabase.instance.client; // Supabase client instance

  @override
  void initState() {
    super.initState();
    // Delay navigation for 3 seconds before checking user session
    Timer(const Duration(seconds: 3), _navigate);
  }

  // Check if user is logged in and navigate accordingly
  void _navigate() {
    final user = supabase.auth.currentUser;

    if (user != null) {
      // Navigate to home screen if user session is active
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Otherwise go to login screen
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // UI for splash screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            // App logo image
            Image.asset(
              'assets/images/logo.png',
              width: 180,
              height: 180,
            ),

            const SizedBox(height: 30),

            // App title text
            Text(
              'Find My Lost',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
