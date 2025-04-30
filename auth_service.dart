// Import required packages
import 'package:flutter/material.dart'; // Flutter UI
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase SDK for auth and database

// AuthService handles authentication logic using Supabase
class AuthService {
  final SupabaseClient supabase =
      Supabase.instance.client; // Supabase client instance

  //  Sign in with email and password
  Future<bool> signInWithEmail(
      BuildContext context, String email, String password) async {
    try {
      // Try to log in
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        // Get the user's role from the 'users' table
        final userRoleResponse = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        final role = userRoleResponse?['role'] ?? 'user';

        if (!context.mounted) return false;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Logged in successfully as $role!"),
            backgroundColor: Colors.green,
          ),
        );

        return true;
      } else {
        if (!context.mounted) return false;
        _showError(context, "❌ Invalid email or password.");
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      _showError(context, "❌ Login error: ${e.toString()}");
      return false;
    }
  }

  //  Sign up with email and password, and store user with role
  Future<bool> signUpWithEmail(
    BuildContext context,
    String email,
    String password, {
    String role = 'user',
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        // Insert user into 'users' table with role
        await supabase.from('users').insert({
          'id': user.id,
          'email': email,
          'role': role,
        });

        if (!context.mounted) return false;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Registration successful! Check your email."),
            backgroundColor: Colors.green,
          ),
        );

        return true;
      } else {
        if (!context.mounted) return false;
        _showError(context, "❌ Couldn't create account.");
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      _showError(context, "❌ Registration error: ${e.toString()}");
      return false;
    }
  }

  //  Sign out from Supabase auth
  Future<void> signOut(BuildContext context) async {
    try {
      await supabase.auth.signOut();

      if (!context.mounted) return;

      // Show logout confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Logged out successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, "❌ Logout error: ${e.toString()}");
    }
  }

  //  Return currently signed-in user
  User? getCurrentUser() => supabase.auth.currentUser;

  //  Stream for listening to auth state changes (signed in/out)
  Stream<AuthState> getAuthState() => supabase.auth.onAuthStateChange;

  //  Helper to show error messages via snackbar
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
