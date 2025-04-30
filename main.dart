// Import Flutter and Supabase dependencies
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import screens
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/map_screen.dart';
import 'screens/match_items_screen.dart';
import 'screens/full_map_screen.dart';
import 'screens/add_lost_item_screen.dart';
import 'screens/add_found_item_screen.dart';
import 'screens/match_detail_screen.dart';
import 'screens/select_location_screen.dart';
import 'screens/splash_screen.dart';
import 'package:latlong2/latlong.dart';

void main() async {
  // Ensure binding before initializing async code
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase connection
    await Supabase.initialize(
      url: '',
      anonKey: '',
    );

    runApp(const MyApp());
  } catch (e) {
    // If Supabase initialization fails, show error screen
    runApp(
        ErrorApp(errorMessage: "Error initializing Supabase: ${e.toString()}"));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find My Lost',
      debugShowCheckedModeBanner: false,

      // App theme configuration
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.indigo,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),

      // Default route on app launch
      initialRoute: '/',

      // Named route definitions
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/map': (_) => const MapScreen(),
        '/matched-items': (_) => const MatchedItemsScreen(),
        '/add-lost': (_) => const AddLostItemScreen(),
        '/add-found': (_) => const AddFoundItemScreen(),
        '/select-location': (_) => const SelectLocationScreen(),
      },

      // Dynamic route handling for screens needing arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/full-map' && settings.arguments is LatLng) {
          final location = settings.arguments as LatLng;
          return MaterialPageRoute(
              builder: (_) => FullMapScreen(location: location));
        }

        if (settings.name == '/match-details' &&
            settings.arguments is Map<String, dynamic>) {
          final item = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (_) => MatchDetailScreen(itemData: item));
        }

        // Fallback route
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      },
    );
  }
}

// Error screen in case Supabase fails to initialize
class ErrorApp extends StatelessWidget {
  final String errorMessage;
  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade100,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
