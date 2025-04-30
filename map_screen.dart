// Import necessary packages
import 'package:flutter/material.dart'; // Flutter UI
import 'package:flutter_map/flutter_map.dart'; // For map rendering
import 'package:latlong2/latlong.dart'; // For latitude/longitude data
import 'package:google_fonts/google_fonts.dart'; // For custom fonts

// Stateful widget for selecting a location on the map
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  // Default location set to Riyadh, Saudi Arabia
  LatLng selectedLocation = const LatLng(24.7136, 46.6753);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with title and back button
      appBar: AppBar(
        title: Text('Select Location', style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pop(context), // Go back without returning location
        ),
      ),
      backgroundColor: Colors.white,

      // Map UI using flutter_map
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: selectedLocation, // Initial center of the map
              initialZoom: 10.0, // Zoom level
              onTap: (tapPosition, point) {
                setState(() {
                  selectedLocation = point; // Update selected location on tap
                });
              },
            ),
            children: [
              // Base map layer from OpenStreetMap
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              // Marker to indicate the selected point
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 50.0,
                    height: 50.0,
                    child: const Icon(Icons.location_pin,
                        color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Confirm button to return the selected location
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        onPressed: () {
          Navigator.pop(context,
              selectedLocation); // Return selected location to previous screen
        },
        icon: const Icon(Icons.check, color: Colors.white),
        label: Text("Confirm Location",
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
