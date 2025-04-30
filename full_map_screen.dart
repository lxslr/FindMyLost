// Import required packages
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:flutter_map/flutter_map.dart'; // For displaying interactive maps
import 'package:latlong2/latlong.dart'; // For geographical coordinates
import 'package:google_fonts/google_fonts.dart'; // For using Google Fonts

// StatelessWidget to display a full map with a marker at a given location
class FullMapScreen extends StatelessWidget {
  final LatLng location; // Location to be shown on the map

  const FullMapScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with title and styling
      appBar: AppBar(
        title: Text("Item Location", style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      backgroundColor: Colors.white,

      // Map display using flutter_map
      body: FlutterMap(
        options: MapOptions(
          initialCenter: location, // Center the map on the provided location
          initialZoom: 16, // Set initial zoom level
        ),
        children: [
          // Tile layer using OpenStreetMap
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.find_my_lost',
          ),
          // Marker to show the item’s location
          MarkerLayer(
            markers: [
              Marker(
                point: location,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
