// Import required packages
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase integration
import 'package:google_fonts/google_fonts.dart'; // Google Fonts styling

// Screen for user registration
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final supabase = Supabase.instance.client; // Supabase client instance

  // Controllers for form fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false; // Loading state for registration button

  // Helper function to display error snackbar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.indigo[50],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.indigo),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.indigo[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Handles registration logic using Supabase Auth
  Future<void> _register() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = response.session?.user ?? response.user;

      if (user != null) {
        // Store additional user data in the 'users' table
        await supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'role': 'user',
        });

        if (!mounted) return;

        // Show dialog prompting user to verify email
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.indigo[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              "Email Confirmation Sent",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "A confirmation email has been sent to your inbox.",
              style: GoogleFonts.poppins(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        _showError("❌ Couldn't retrieve user info");
      }
    } catch (e) {
      debugPrint("❌ Registration error: $e");
      _showError("❌ Registration failed");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Dispose text controllers to avoid memory leaks
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Build the registration form UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Create Account", style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.person_add_alt_1, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),

            // Email input field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email, color: Colors.indigo),
                labelText: 'Email',
                labelStyle: GoogleFonts.poppins(),
                filled: true,
                fillColor: Colors.indigo[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Password input field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock, color: Colors.indigo),
                labelText: 'Password',
                labelStyle: GoogleFonts.poppins(),
                filled: true,
                fillColor: Colors.indigo[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Sign up button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Sign Up",
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),

            // Navigation to login screen
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                "Already have an account? Login",
                style: GoogleFonts.poppins(color: Colors.indigo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
