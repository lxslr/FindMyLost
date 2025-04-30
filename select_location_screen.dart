// Import required packages
import 'dart:async'; // For using Completer
import 'package:flutter/material.dart'; // Flutter UI
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Google Maps plugin
import 'package:geolocator/geolocator.dart'; // Geolocation services
import 'package:google_fonts/google_fonts.dart'; // Google Fonts

// Stateful screen to select location using Google Maps
class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final Completer<GoogleMapController> _controller =
      Completer(); // Controller for GoogleMap
  LatLng? selectedLocation; // Stores selected location
  bool isLoading = true; // Indicates if location is loading
  String? errorMessage; // Stores error message if location fetch fails

  @override
  void initState() {
    super.initState();
    _initLocation(); // Start getting user location on init
  }

  // Try to fetch current GPS location or fallback to Riyadh
  Future<void> _initLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "⚠ Unable to get location. Please enable GPS.";
        isLoading = false;
        selectedLocation = const LatLng(24.7136, 46.6753); // Fallback to Riyadh
      });
    }
  }

  // Return the selected location to previous screen
  void _confirmLocation() {
    if (selectedLocation != null) {
      Navigator.pop(context, selectedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Please select a location.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build the map screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Select Location", style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading spinner
          : Stack(
              children: [
                // Google Map widget
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedLocation ?? const LatLng(24.7136, 46.6753),
                    zoom: 15.0,
                  ),
                  onMapCreated: (controller) =>
                      _controller.complete(controller),
                  onTap: (LatLng location) {
                    setState(() =>
                        selectedLocation = location); // Update location on tap
                  },
                  markers: selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId("selected-location"),
                            position: selectedLocation!,
                          ),
                        }
                      : {},
                ),

                // Show error banner if location not available
                if (errorMessage != null)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Confirmation button at the bottom
                Positioned(
                  bottom: 20,
                  left: 40,
                  right: 40,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text("Confirm Location",
                        style: GoogleFonts.poppins(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _confirmLocation,
                  ),
                ),
              ],
            ),
    );
  }
}
