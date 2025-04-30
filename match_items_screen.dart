// Import necessary packages
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/match_service.dart';
import 'match_detail_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

// Screen that displays all matched found items for a user
class MatchedItemsScreen extends StatefulWidget {
  const MatchedItemsScreen({super.key});

  @override
  State<MatchedItemsScreen> createState() => _MatchedItemsScreenState();
}

class _MatchedItemsScreenState extends State<MatchedItemsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> matchedItems = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final matches = await findMatchingFoundItems();
    if (!mounted) return;
    setState(() => matchedItems = matches);
  }

  Future<void> _confirmItemOwnership(Map<String, dynamic> item) async {
    await supabase
        .from('found_items')
        .update({'status': 'claimed'}).eq('id', item['id']);
    await supabase
        .from('rejected_matches')
        .delete()
        .eq('found_item_id', item['id']);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.indigo[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text("🎉 ", style: TextStyle(fontSize: 22)),
            Text("Match Confirmed!",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Contact the reporter at:", style: GoogleFonts.poppins()),
            const SizedBox(height: 6),
            Text(
              item['contact_info'] ?? 'No contact info',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: Colors.indigo),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await supabase
                  .from('found_items')
                  .update({'status': 'returned'}).eq('id', item['id']);
              if (!mounted) return;
              Navigator.pop(context);
              _loadMatches();
            },
            child: Text("✔️ Mark as Returned",
                style: GoogleFonts.poppins(color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectItem(Map<String, dynamic> item) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('rejected_matches').insert({
      'user_id': userId,
      'found_item_id': item['id'],
    });

    if (!mounted) return;
    setState(() {
      matchedItems
          .removeWhere((e) => e['id'].toString() == item['id'].toString());
    });
  }

  LatLng? _parseLatLng(String? location) {
    if (location == null) return null;
    try {
      final parts = location.split(',');
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Matched Items",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: matchedItems.isEmpty
          ? Center(
              child: Text("No matches found.", style: GoogleFonts.poppins()))
          : ListView.builder(
              itemCount: matchedItems.length,
              itemBuilder: (context, index) {
                final item = matchedItems[index];
                final latLng = _parseLatLng(item['location']);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MatchDetailScreen(itemData: item),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          _buildImageThumbnail(item),
                          const SizedBox(width: 16),
                          Expanded(child: _buildItemDetails(item, latLng)),
                          _buildPopupMenu(item),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildImageThumbnail(Map<String, dynamic> item) {
    final url = item['image_url'];
    if (url != null && url.toString().startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _placeholderImage();
          },
        ),
      );
    } else {
      return _placeholderImage();
    }
  }

  Widget _placeholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
    );
  }

  Widget _buildItemDetails(Map<String, dynamic> item, LatLng? latLng) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${item['item_type']} - ${item['color']}",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Brand: ${item['brand']}",
            style: GoogleFonts.poppins(fontSize: 14)),
        Text("Found: ${item['date_found']}",
            style: GoogleFonts.poppins(fontSize: 14)),
        const SizedBox(height: 6),
        Text(
          latLng != null
              ? "📍 Lat: ${latLng.latitude.toStringAsFixed(4)}, Lng: ${latLng.longitude.toStringAsFixed(4)}"
              : "Location not available",
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(Map<String, dynamic> item) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'mine') {
          _confirmItemOwnership(item);
        } else if (value == 'not_mine') {
          _rejectItem(item);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'mine', child: Text("This item is mine")),
        const PopupMenuItem(value: 'not_mine', child: Text("Not mine")),
      ],
    );
  }
}
