import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditListingPage extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic> existingData;

  const EditListingPage({
    super.key,
    required this.listingId,
    required this.existingData,
  });

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingData['title']);
    _priceController = TextEditingController(text: widget.existingData['price'].toString());
    _descController = TextEditingController(text: widget.existingData['description']);
    _phoneController = TextEditingController(text: widget.existingData['phone']);
  }

  Future<void> _updateListing() async {
    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .update({
        'title': _titleController.text.trim(),
        'price': _priceController.text.trim(),
        'description': _descController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing updated successfully.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Listing')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: _updateListing,
            ),
          ],
        ),
      ),
    );
  }
}
