// Import necessary packages
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // For local notifications
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase client
import 'add_lost_item_screen.dart'; // Screen to add a lost item
import 'add_found_item_screen.dart'; // Screen to add a found item
import '../services/match_service.dart'; // Custom service to find matches
import 'package:google_fonts/google_fonts.dart'; // Google Fonts for styling
import 'package:badges/badges.dart' as badges; // Package for badge UI

// Main home screen widget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // Local notifications plugin instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Supabase client instance
  final supabase = Supabase.instance.client;

  int matchedCount = 0; // Number of matched items

  @override
  void initState() {
    super.initState();
    _initNotifications(); // Initialize local notifications
    _checkForMatches(); // Check for matching found items
  }

  // Initialize local notification settings for Android
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show a local notification for a matched item
  Future<void> _showNotification(
      String title, String body, Map<String, dynamic> foundItem) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'lost_found_channel',
      'Lost & Found Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: foundItem.toString(), // Optional: use for navigation payload
    );
  }

  // Check for matching found items using custom service
  Future<void> _checkForMatches() async {
    final matches = await findMatchingFoundItems(); // Get list of matches

    if (mounted) {
      setState(() {
        matchedCount = matches.length; // Update badge count
      });
    }

    // Show a notification for each match
    for (final item in matches) {
      _showNotification(
        "Match Found!",
        "A ${item['item_type']} matching your lost item was found.",
        item,
      );
    }
  }

  // Build method for UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Find My Lost',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Notification icon with badge showing match count
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: badges.Badge(
              showBadge: matchedCount > 0,
              badgeContent: Text(
                matchedCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(5),
              ),
              position: badges.BadgePosition.topEnd(top: 2, end: 2),
              child: IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/matched-items');
                  _checkForMatches(); // Re-check matches on return
                },
              ),
            ),
          ),
          // Profile icon button
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile'); // Navigate to profile
            },
          ),
        ],
      ),

      // Main body with buttons
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Button to navigate to Add Lost Item screen
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: Text("Add Lost Item",
                    style: GoogleFonts.poppins(fontSize: 18)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddLostItemScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 20),

              // Button to navigate to Add Found Item screen
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text("Add Found Item",
                    style: GoogleFonts.poppins(fontSize: 18)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddFoundItemScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
