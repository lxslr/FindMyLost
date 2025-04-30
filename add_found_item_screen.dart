// Import necessary packages
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'map_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// Screen for adding a found item
class AddFoundItemScreen extends StatefulWidget {
  const AddFoundItemScreen({super.key});
  @override
  State<AddFoundItemScreen> createState() => _AddFoundItemScreenState();
}

class _AddFoundItemScreenState extends State<AddFoundItemScreen> {
  // Initialize Supabase client and image picker
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  // Controllers for form fields
  final brandController = TextEditingController();
  final colorController = TextEditingController();
  final dateFoundController = TextEditingController();
  final contactInfoController = TextEditingController();
  final locationController = TextEditingController();

  // Dropdown selection for item type
  String? selectedType;
  final List<String> itemTypes = [
    'Car',
    'Watch',
    'Wallet',
    'Bank Card',
    'Phone',
    'Laptop',
    'Bag',
    'Keys',
    'Headphones',
    'Glasses',
    'Passport',
    'Jewelry',
    'Other'
  ];

  // Variables for selected location and image
  LatLng? selectedLocation;
  File? _image;
  bool isSaving = false; // Controls loading state

  // Pick an image from camera or gallery
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  // Show dialog to choose image source
  Future<void> _showImagePickerDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take Photo"),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Choose from Gallery"),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  // Navigate to map screen to pick location
  Future<void> _pickLocation() async {
    final LatLng? location = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );

    if (location != null) {
      setState(() {
        selectedLocation = location;
        locationController.text =
            "Lat: ${location.latitude}, Lng: ${location.longitude}";
      });
    }
  }

  // Show date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        dateFoundController.text =
            "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
      });
    }
  }

  // Upload image to Supabase Storage and return public URL
  Future<String?> uploadImage(File image) async {
    try {
      final fileName =
          'founditems/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await image.readAsBytes();

      await supabase.storage.from('founditems').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return supabase.storage.from('founditems').getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  // Save found item data to Supabase
  Future<void> saveFoundItem() async {
    // Validate required fields
    if (selectedType == null ||
        brandController.text.isEmpty ||
        colorController.text.isEmpty ||
        dateFoundController.text.isEmpty ||
        selectedLocation == null ||
        contactInfoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠ Please fill all fields and select a location.")),
      );
      return;
    }

    setState(() => isSaving = true);

    // Upload image if exists
    String? imageUrl;
    if (_image != null) {
      imageUrl = await uploadImage(_image!);
    }

    try {
      // Insert item data into database
      final response = await supabase.from('found_items').insert({
        'item_type': selectedType,
        'brand': brandController.text.trim(),
        'color': colorController.text.trim(),
        'date_found': dateFoundController.text.trim(),
        'location':
            "${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
        'contact_info': contactInfoController.text.trim(),
        'image_url': imageUrl ?? '',
        'user_id': supabase.auth.currentUser!.id,
      }).select();

      if (!mounted) return;

      // Show success message and go back
      if (response.isNotEmpty) {
        _showSuccessSnackBar("Item added successfully!");
        Navigator.pop(context);
      } else {
        throw Exception("Failed to insert data.");
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving item: ${e.toString()}")),
        );
      }
    }

    if (mounted) setState(() => isSaving = false);
  }

  // Show success snackbar with custom style
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build text fields with common style
  Widget _buildTextField(TextEditingController controller, String label,
      {bool readOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        filled: true,
        fillColor: Colors.indigo[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Build the full UI for the screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Found Item", style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image upload section
            GestureDetector(
              onTap: _showImagePickerDialog,
              child: _image == null
                  ? Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 50, color: Colors.grey),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 20),

            // Dropdown for item type
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Item Type',
                labelStyle: GoogleFonts.poppins(),
                filled: true,
                fillColor: Colors.indigo[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              value: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
              items: itemTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, style: GoogleFonts.poppins()),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 15),

            // Input fields
            _buildTextField(brandController, 'Brand'),
            const SizedBox(height: 15),
            _buildTextField(colorController, 'Color'),
            const SizedBox(height: 15),
            _buildTextField(dateFoundController, 'Date Found',
                readOnly: true, onTap: () => _selectDate(context)),
            const SizedBox(height: 15),
            _buildTextField(contactInfoController, 'Contact Information'),
            const SizedBox(height: 15),
            _buildTextField(locationController, 'Location',
                readOnly: true, onTap: _pickLocation),
            const SizedBox(height: 30),

            // Submit button or loading indicator
            isSaving
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveFoundItem,
                      child: Text("Submit",
                          style: GoogleFonts.poppins(fontSize: 16)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
