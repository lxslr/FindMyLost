// Import necessary packages
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase integration
import 'package:google_fonts/google_fonts.dart'; // Google Fonts for styling

// Profile screen showing user info and statistics
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client; // Supabase client

  // User data fields
  String email = '';
  String role = '';
  int lostItemCount = 0;
  int foundItemCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Load user data on screen load
  }

  // Fetch user email, role and item stats from Supabase
  Future<void> _fetchUserData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        // Get email and role from users table
        final userInfo = await supabase
            .from('users')
            .select('email, role')
            .eq('id', user.id)
            .single();

        // Count user's lost and found items
        final lostItems = await supabase
            .from('lost_items')
            .select('id')
            .eq('user_id', user.id);

        final foundItems = await supabase
            .from('found_items')
            .select('id')
            .eq('user_id', user.id);

        if (!mounted) return;
        setState(() {
          email = userInfo['email'] ?? 'No Email';
          role = userInfo['role'] ?? 'user';
          lostItemCount = lostItems.length;
          foundItemCount = foundItems.length;
        });
      } catch (e) {
        debugPrint("❌ Error fetching user info: $e");
      }
    }
  }

  // Sign the user out and navigate to login screen
  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Build profile UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Profile",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.indigo),
            const SizedBox(height: 16),
            Text(
              email,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.indigo[900],
              ),
            ),
            Text(
              "Role: $role",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // Stats card showing lost/found items count
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.indigo[50],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          "Lost Items: $lostItemCount",
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          "Found Items: $foundItemCount",
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label:
                    Text("Sign Out", style: GoogleFonts.poppins(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
