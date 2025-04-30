// Import Supabase client
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client instance
final supabase = Supabase.instance.client;

// Find matching found items based on the current user's lost items
Future<List<Map<String, dynamic>>> findMatchingFoundItems() async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  //  Get IDs of found items previously rejected by this user
  final rejectedResponse = await supabase
      .from('rejected_matches')
      .select('found_item_id')
      .eq('user_id', user.id);

  final rejectedIds =
      rejectedResponse.map((r) => r['found_item_id'].toString()).toSet();

  //  Get current user's lost items
  final lostItems =
      await supabase.from('lost_items').select().eq('user_id', user.id);

  //  Get found items, excluding those already returned
  final foundAll =
      await supabase.from('found_items').select().neq('status', 'returned');

  //  Filter out items the user rejected previously
  final foundItems = List<Map<String, dynamic>>.from(foundAll)
      .where((item) => !rejectedIds.contains(item['id'].toString()))
      .toList();

  List<Map<String, dynamic>> matches = [];

  //  Match logic: iterate lost vs found items
  for (var lost in lostItems) {
    for (var found in foundItems) {
      final itemTypeMatch =
          _compareExact(lost['item_type'], found['item_type']);
      final brandMatch = _compareExact(lost['brand'], found['brand']);
      final colorMatch = _partialMatch(lost['color'], found['color']);
      final dateMatch = _isDateMatch(lost['date_lost'], found['date_found']);

      //  If all match rules pass, it's a match
      if (itemTypeMatch && brandMatch && colorMatch && dateMatch) {
        matches.add({...found, 'matched_with': lost});
      }
    }
  }

  return matches;
}

// Exact match ignoring case and whitespaces
bool _compareExact(dynamic a, dynamic b) {
  return a.toString().toLowerCase().trim() == b.toString().toLowerCase().trim();
}

// Partial match (e.g., "black" in "matte black")
bool _partialMatch(dynamic a, dynamic b) {
  final textA = a.toString().toLowerCase().trim();
  final textB = b.toString().toLowerCase().trim();
  return textA.contains(textB) || textB.contains(textA);
}

// Checks if the lost/found dates are within 3 days of each other
bool _isDateMatch(String? lostDate, String? foundDate) {
  if (lostDate == null || foundDate == null) return false;

  final lost = DateTime.tryParse(lostDate);
  final found = DateTime.tryParse(foundDate);
  if (lost == null || found == null) return false;

  final diffDays = lost.difference(found).inDays.abs();
  return diffDays <= 3;
}
