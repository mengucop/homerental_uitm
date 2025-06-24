import 'package:flutter/material.dart';
import 'home_page.dart';
import 'add_listing_page.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'my_listings_page.dart'; // ✅ New import

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    Placeholder(), // FAB target
    MapPage(),
    MyListingsPage(), // ✅ New My Listings tab
    ProfilePage(),
  ];

  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddListingPage()),
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddListingPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabIcon(Icons.home, 0, "Home"),
              _buildTabIcon(Icons.map, 2, "Map"),
              const SizedBox(width: 30), // FAB space
              _buildTabIcon(Icons.list_alt, 3, "My Listings"), // ✅ New Tab
              _buildTabIcon(Icons.person, 4, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, int index, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.deepPurple : Colors.grey),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.deepPurple : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
