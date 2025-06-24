import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'listing_detail_page.dart';
import 'edit_listing_page.dart'; // Ensure this file exists

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in to view your listings.')),
      );
    }

    final userEmail = currentUser.email?.toLowerCase() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('owner', isEqualTo: userEmail) // ← Updated field for lowercase email
            .snapshots(),
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            print("Error loading listings: ${snapshot.error}");
            return const Center(child: Text("❌ Error loading listings"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("📭 You haven't posted any listings yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                elevation: 5,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          data['imageUrl'],
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'No Title',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text("RM${data['price'] ?? 'N/A'}"),
                          const SizedBox(height: 8),
                          if (data['latitude'] != null && data['longitude'] != null)
                            SizedBox(
                              height: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(data['latitude'], data['longitude']),
                                    zoom: 14,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: MarkerId(docId),
                                      position: LatLng(data['latitude'], data['longitude']),
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  liteModeEnabled: true,
                                  onTap: (_) {},
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                label: const Text("Edit"),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditListingPage(
                                        listingId: docId,
                                        existingData: data,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text("Delete"),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Delete Listing"),
                                      content: const Text("Are you sure you want to delete this listing?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('listings')
                                        .doc(docId)
                                        .delete();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Listing deleted.")),
                                    );
                                  }
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.visibility),
                                label: const Text("View"),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ListingDetailPage(
                                        title: data['title'] ?? '',
                                        description: data['description'] ?? '',
                                        price: data['price']?.toString() ?? '',
                                        imageUrl: data['imageUrl'] ?? '',
                                        latitude: data['latitude'] ?? 0,
                                        longitude: data['longitude'] ?? 0,
                                        phone: data['phone'] ?? '',
                                        email: data['email'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
