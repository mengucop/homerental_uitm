import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _imageFile;
  final picker = ImagePicker();
  late GoogleMapController _mapController;

  LatLng _selectedLocation = const LatLng(6.4431, 100.2743);

  String? selectedCategory;
  final List<String> categories = ['Room', 'Apartment', 'House'];

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final price = _priceController.text.trim();
    final desc = _descController.text.trim();
    final phone = _phoneController.text.trim();
    final userEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();

    if (title.isEmpty || price.isEmpty || desc.isEmpty || phone.isEmpty || selectedCategory == null || _imageFile == null || userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields, image, and location')),
      );
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance
          .ref('listing_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_imageFile!);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('listings').add({
        'title': title,
        'price': price,
        'description': desc,
        'imageUrl': imageUrl,
        'phone': phone,
        'owner': userEmail, // ✅ store lowercase email as 'owner'
        'category': selectedCategory,
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing added successfully!')),
      );

      _titleController.clear();
      _priceController.clear();
      _descController.clear();
      _phoneController.clear();
      setState(() {
        _imageFile = null;
        selectedCategory = null;
        _selectedLocation = const LatLng(6.4431, 100.2743);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📝 Add New Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏷️ Title'),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Cozy Room near UiTM',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            const Text('💰 Price (RM)'),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 450',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            const Text('📝 Description'),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Provide a detailed description...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            const Text('📞 Phone'),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'e.g. 0123456789',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            const Text('🏠 Category'),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              )).toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
              decoration: const InputDecoration(
                hintText: 'Select category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            const Text('🖼️ Image'),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Choose Image'),
                ),
                const SizedBox(width: 16),
                if (_imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _imageFile!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            const Text("📍 Tap on the map to select location:"),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: 16,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onTap: (LatLng pos) {
                  setState(() => _selectedLocation = pos);
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: _selectedLocation,
                  ),
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '📌 Lat: ${_selectedLocation.latitude}, Lng: ${_selectedLocation.longitude}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Submit Listing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
