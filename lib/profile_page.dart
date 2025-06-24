import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'dart:io';
import 'notifications_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  bool isDarkMode = false;
  final _phoneController = TextEditingController();
  String? profileImageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _getProfileImage();
    _getUserPhone();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDarkMode = prefs.getBool('isDarkMode') ?? false);
  }

  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDarkMode = !isDarkMode);
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _updatePhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'phone': phone, 'email': user!.email}, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number updated')),
      );
    }
  }

  Future<void> _getProfileImage() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    setState(() {
      profileImageUrl = userDoc['profileImageUrl'] ?? null;
    });
  }

  Future<void> _getUserPhone() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (userDoc.exists && userDoc.data()!.containsKey('phone')) {
      _phoneController.text = userDoc['phone'];
    }
  }

  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => isLoading = true);
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref('profile_pictures/${user!.uid}.jpg');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'profileImageUrl': imageUrl}, SetOptions(merge: true));

      setState(() {
        profileImageUrl = imageUrl;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: _toggleDarkMode,
            tooltip: 'Toggle Theme',
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .doc(user!.uid)
                .collection('items')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage()),
                      );
                    },
                    tooltip: 'View Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 10,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _updateProfileImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.indigo.shade200,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                  child: profileImageUrl == null
                      ? const Icon(Icons.person, size: 80, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Hello, ${user?.displayName ?? 'User'}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                user?.email ?? 'No email',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Update Phone'),
              onPressed: _updatePhone,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
