import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_page.dart';
import 'listing_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = '';
  String selectedPriceRange = 'All';
  String selectedSort = 'Newest';
  final TextEditingController _searchController = TextEditingController();

  final List<String> priceOptions = [
    'All',
    'Below RM500',
    'RM500 - RM1000',
    'Above RM1000',
  ];

  bool matchesSearch(Map<String, dynamic> data) {
    final title = data['title']?.toLowerCase() ?? '';
    final location = data['location']?.toLowerCase() ?? '';
    return title.contains(searchQuery.toLowerCase()) ||
        location.contains(searchQuery.toLowerCase());
  }

  bool matchesPrice(Map<String, dynamic> data) {
    final rawPrice = data['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString()) ?? 0.0;

    switch (selectedPriceRange) {
      case 'Below RM500':
        return price < 500;
      case 'RM500 - RM1000':
        return price >= 500 && price <= 1000;
      case 'Above RM1000':
        return price > 1000;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HomeRentalUiTM")),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // simple refresh
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Header Section
            const Text(
              "🏡 Welcome back!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text("Find your ideal UiTM home rental easily."),
            const SizedBox(height: 12),

            // Search Field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Search by title or location",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
            const SizedBox(height: 10),

            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPriceRange,
                    items: priceOptions.map((option) {
                      return DropdownMenuItem(value: option, child: Text(option));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedPriceRange = value ?? 'All'),
                    decoration: const InputDecoration(
                      labelText: "Price",
                      prefixIcon: Icon(Icons.monetization_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSort,
                    items: const [
                      DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'Price Low to High', child: Text('Low → High')),
                      DropdownMenuItem(value: 'Price High to Low', child: Text('High → Low')),
                    ],
                    onChanged: (value) => setState(() => selectedSort = value ?? 'Newest'),
                    decoration: const InputDecoration(
                      labelText: "Sort",
                      prefixIcon: Icon(Icons.sort),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Clear Filters
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                    selectedPriceRange = 'All';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text("Clear Filters"),
              ),
            ),

            // View on Map
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text("View Listings on Map"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));
              },
            ),

            const SizedBox(height: 10),

            // Listings from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("❌ Error loading listings"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return matchesSearch(data) && matchesPrice(data);
                }).toList();

                if (selectedSort == 'Price Low to High') {
                  filtered.sort((a, b) {
                    final aPrice = double.tryParse((a.data() as Map)['price'].toString()) ?? 0;
                    final bPrice = double.tryParse((b.data() as Map)['price'].toString()) ?? 0;
                    return aPrice.compareTo(bPrice);
                  });
                } else if (selectedSort == 'Price High to Low') {
                  filtered.sort((a, b) {
                    final aPrice = double.tryParse((a.data() as Map)['price'].toString()) ?? 0;
                    final bPrice = double.tryParse((b.data() as Map)['price'].toString()) ?? 0;
                    return bPrice.compareTo(aPrice);
                  });
                }

                if (filtered.isEmpty) return const Text("😕 No results found");

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🔥 Featured Listings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filtered.length > 5 ? 5 : filtered.length,
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildCard(context, data);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("📋 All Listings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...filtered.skip(5).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildCard(context, data);
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              price: data['price'].toString(),
              imageUrl: data['imageUrl'] ?? '',
              latitude: data['latitude'] ?? 0.0,
              longitude: data['longitude'] ?? 0.0,
              phone: data['phone'] ?? '',
              email: data['email'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['imageUrl'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  data['imageUrl'],
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("RM ${data['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  if (data['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(data['category'], style: const TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
