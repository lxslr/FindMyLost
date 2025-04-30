// Import necessary packages
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:flutter_map/flutter_map.dart'; // Flutter map plugin
import 'package:latlong2/latlong.dart'; // LatLng class for coordinates
import 'package:google_fonts/google_fonts.dart'; // Google Fonts package

// Screen to show detailed info about a matched item
class MatchDetailScreen extends StatelessWidget {
  final Map<String, dynamic> itemData; // Data of the matched item

  const MatchDetailScreen({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
    final latLng = _extractLatLng(itemData['location']);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Match Details",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(itemData['image_url']),
            const SizedBox(height: 20),
            _buildDetail("Item Type", itemData['item_type']),
            _buildDetail("Brand", itemData['brand']),
            _buildDetail("Color", itemData['color']),
            _buildDetail("Found Date", itemData['date_found']),
            _buildDetail("Contact Info", itemData['contact_info']),
            const SizedBox(height: 20),
            Text("Location",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            latLng != null ? _buildMap(latLng) : _noLocationWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  const Icon(Icons.broken_image, size: 50, color: Colors.grey),
            );
          },
        ),
      );
    } else {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.indigo[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      );
    }
  }

  Widget _buildMap(LatLng latLng) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: latLng,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.find_my_lost',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: latLng,
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.location_pin,
                      color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _noLocationWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        "⚠️ Location not available.",
        style: GoogleFonts.poppins(color: Colors.red),
      ),
    );
  }

  Widget _buildDetail(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              "$title: ",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 4,
            child: Text(
              value?.toString() ?? "-",
              style: GoogleFonts.poppins(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  LatLng? _extractLatLng(String? location) {
    try {
      if (location == null) return null;

      if (location.contains("Lat:") && location.contains("Lng:")) {
        final parts = location.split(',');
        final lat = double.parse(parts[0].split(':')[1].trim());
        final lng = double.parse(parts[1].split(':')[1].trim());
        return LatLng(lat, lng);
      } else {
        final parts = location.split(',');
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
    } catch (e) {
      return null;
    }
  }
}
