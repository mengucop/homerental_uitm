import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_analytics_page.dart';
import 'broadcast_notification_page.dart';
import 'moderate_listings_page.dart';
import '../login_page.dart';
import 'export_pdf_util.dart'; // 👈 Make sure this exists

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠 Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // 👤 Admin Avatar and Email
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.indigo.shade100,
              child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.indigo),
            ),
            const SizedBox(height: 10),
            Text(
              email,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30, thickness: 1),

            // 🧩 Dashboard Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildAdminCard(
                    context,
                    icon: Icons.fact_check,
                    title: "Moderate Listings",
                    color: Colors.orange,
                    destination: const ModerateListingsPage(),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.campaign,
                    title: "Broadcast Notification",
                    color: Colors.indigo,
                    destination: const BroadcastNotificationPage(),
                  ),
                  _buildAdminCard(
                    context,
                    icon: Icons.analytics,
                    title: "Analytics",
                    color: Colors.green,
                    destination: const AdminAnalyticsPage(),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.picture_as_pdf,
                    title: "Export Listings PDF",
                    color: Colors.deepPurple,
                    onTap: () => ExportPDFUtil.exportListingsToPDF(context),
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.people,
                    title: "Export Users PDF",
                    color: Colors.teal,
                    onTap: () => ExportPDFUtil.exportUsersToPDF(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page navigation card
  Widget _buildAdminCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required Widget destination,
      }) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: color),
                const SizedBox(height: 10),
                Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Instant action card (no navigation)
  Widget _buildActionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: color),
                const SizedBox(height: 10),
                Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
