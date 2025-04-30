// Import required packages
import 'package:flutter/material.dart'; // UI toolkit
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase client
import 'package:google_fonts/google_fonts.dart'; // Google Fonts for consistent styling

// Stateful widget for the login screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final supabase = Supabase.instance.client; // Supabase instance
  final emailController = TextEditingController(); // Controller for email input
  final passwordController =
      TextEditingController(); // Controller for password input
  bool isLoading = false; // Loading state for login process

  // Handles the login process
  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("⚠ Please fill in all fields.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (!mounted) return;

      if (user == null) {
        _showSnackBar("❌ Invalid email or password.");
        return;
      }

      if (user.emailConfirmedAt == null) {
        _showSnackBar("⚠ Please verify your email before logging in.");
        return;
      }

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;

      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains("email not confirmed")) {
        _showSnackBar("⚠ Please verify your email before logging in.");
      } else if (errorMsg.contains("invalid login credentials")) {
        _showSnackBar("❌ Invalid email or password.");
      } else {
        debugPrint("Login error: $e");
        _showSnackBar("❌ Unexpected error occurred.");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Opens a dialog to reset password via email
  Future<void> _resetPassword() async {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reset Password",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: resetEmailController,
          decoration: InputDecoration(
            hintText: "Enter your email",
            hintStyle: GoogleFonts.poppins(color: Colors.grey),
            filled: true,
            fillColor: Colors.indigo[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: GoogleFonts.poppins(color: Colors.indigo)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();

              if (!_isValidEmail(email)) {
                if (!mounted) return;
                _showSnackBar("⚠ Please enter a valid email address.");
                return;
              }

              try {
                await supabase.auth.resetPasswordForEmail(email);
                if (!mounted) return;
                Navigator.pop(context);
                _showSnackBar("📩 Password reset link sent!", success: true);
              } catch (_) {
                if (!mounted) return;
                Navigator.pop(context);
                _showSnackBar("❌ Error sending reset link.");
              }
            },
            child: Text("Send",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Simple email validation using regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  // Displays a custom snackbar with feedback
  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? Colors.green[400] : Colors.indigo[50],
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.info_outline,
              color: success ? Colors.white : Colors.indigo,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: success ? Colors.white : Colors.indigo[900],
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

  // Dispose controllers when screen is closed
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Build the login form UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Find My Lost",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.indigo),
              const SizedBox(height: 40),
              _buildTextField(emailController, "Email", Icons.email,
                  TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField(passwordController, "Password", Icons.lock,
                  TextInputType.text,
                  obscure: true),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: Text("Forgot Password?",
                      style: GoogleFonts.poppins(color: Colors.indigo)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Login",
                          style: GoogleFonts.poppins(
                              fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/register'),
                child: Text(
                  "Don't have an account? Sign Up",
                  style: GoogleFonts.poppins(color: Colors.indigo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable text field builder
  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, TextInputType keyboardType,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.indigo[300]),
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        filled: true,
        fillColor: Colors.indigo[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
