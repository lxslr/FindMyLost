// Import necessary packages
import 'dart:io'; // To handle image files
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:image_picker/image_picker.dart'; // For picking images from camera/gallery
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase for storage and database
import 'package:latlong2/latlong.dart'; // For geolocation coordinates
import 'map_screen.dart'; // Custom screen to pick a map location
import 'package:google_fonts/google_fonts.dart'; // To use Google Fonts

// Main screen widget to add a lost item
class AddLostItemScreen extends StatefulWidget {
  const AddLostItemScreen({super.key});

  @override
  State<AddLostItemScreen> createState() => _AddLostItemScreenState();
}

class _AddLostItemScreenState extends State<AddLostItemScreen> {
  final supabase = Supabase.instance.client; // Supabase client
  final picker = ImagePicker(); // Image picker instance

  // Text controllers for form fields
  final brandController = TextEditingController();
  final colorController = TextEditingController();
  final dateLostController = TextEditingController();
  final locationController = TextEditingController();

  LatLng? selectedLocation; // Selected map location
  File? _image; // Selected image file
  bool isSaving = false; // Save operation status flag

  String? selectedType; // Selected item type
  final List<String> itemTypes = [
    // List of predefined item types
    'Car', 'Watch', 'Wallet', 'Bank Card', 'Phone', 'Laptop', 'Bag',
    'Keys', 'Headphones', 'Glasses', 'Passport', 'Jewelry', 'Other'
  ];

  // Function to pick image from camera or gallery
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  // Show bottom sheet dialog for choosing image source
  Future<void> _showImagePickerDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take Photo"),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.camera); // Pick from camera
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Choose from Gallery"),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.gallery); // Pick from gallery
            },
          ),
        ],
      ),
    );
  }

  // Navigate to map screen and pick location
  Future<void> _pickLocation() async {
    final LatLng? location = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );

    if (!mounted) return;
    if (location != null) {
      setState(() {
        selectedLocation = location;
        locationController.text =
            "Lat: ${location.latitude}, Lng: ${location.longitude}";
      });
    }
  }

  // Show date picker and update controller
  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
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

    if (pickedDate != null && mounted) {
      setState(() {
        dateLostController.text =
            "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
      });
    }
  }

  // Upload image to Supabase storage
  Future<String?> uploadImage(File image) async {
    try {
      final fileName = 'lostitems/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await image.readAsBytes();

      await supabase.storage.from('lostitems').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return supabase.storage.from('lostitems').getPublicUrl(fileName);
    } catch (e) {
      debugPrint("❌ Error uploading image: $e");
      return null;
    }
  }

  // Save the lost item to Supabase
  Future<void> saveLostItem() async {
    if (selectedType == null ||
        brandController.text.isEmpty ||
        colorController.text.isEmpty ||
        dateLostController.text.isEmpty ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠ Please fill all fields and select a location.")),
      );
      return;
    }

    setState(() => isSaving = true);

    String? imageUrl;
    if (_image != null) {
      imageUrl = await uploadImage(_image!);
    }

    try {
      final user = supabase.auth.currentUser;
      final response = await supabase.from('lost_items').insert({
        'item_type': selectedType,
        'brand': brandController.text.trim(),
        'color': colorController.text.trim(),
        'date_lost': dateLostController.text.trim(),
        'location':
            "${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
        'image_url': imageUrl ?? '',
        'user_id': user!.id,
      }).select();

      if (!mounted) return;

      if (response.isNotEmpty) {
        _showSuccessSnackBar("Lost item added successfully!");
        Navigator.pop(context); // Return to previous screen
      } else {
        throw Exception("Failed to insert data.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error saving item: ${e.toString()}")),
      );
    }

    if (!mounted) return;
    setState(() => isSaving = false);
  }

  // Display a success message
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

  // Reusable method to build a text input field
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

  // Main build method for the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Lost Item", style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image preview or picker
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
            // Item type dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Item Type',
                labelStyle: GoogleFonts.poppins(),
                filled: true,
                fillColor: Colors.indigo[50],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              value: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
              items: itemTypes
                  .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type, style: GoogleFonts.poppins())))
                  .toList(),
            ),
            const SizedBox(height: 15),
            _buildTextField(brandController, 'Brand'),
            const SizedBox(height: 15),
            _buildTextField(colorController, 'Color'),
            const SizedBox(height: 15),
            _buildTextField(dateLostController, 'Date Lost',
                readOnly: true, onTap: () => _selectDate(context)),
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
                      onPressed: saveLostItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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
