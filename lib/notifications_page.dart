import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  bool showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    if (userId == null) return;
    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      doc.reference.update({'read': true});
    }
  }

  Future<void> _clearAll() async {
    if (userId == null) return;
    final query = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications cleared')),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final comparisonDate = DateTime(date.year, date.month, date.day);

    if (comparisonDate == today) {
      return DateFormat('hh:mm a').format(date);
    } else if (today.difference(comparisonDate).inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in to view notifications.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🔔 Notifications"),
        actions: [
          IconButton(
            icon: Icon(showUnreadOnly ? Icons.visibility_off : Icons.visibility),
            tooltip: showUnreadOnly ? "Show All" : "Show Unread Only",
            onPressed: () => setState(() => showUnreadOnly = !showUnreadOnly),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(userId)
            .collection('items')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('❌ Error loading notifications.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;
          final docs = showUnreadOnly
              ? allDocs.where((doc) => doc['read'] == false).toList()
              : allDocs;

          if (docs.isEmpty) {
            return const Center(child: Text('📭 No notifications.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'No title';
              final body = data['body'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final read = data['read'] ?? false;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await doc.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted')),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: read ? null : Colors.blue.shade50,
                  child: ListTile(
                    onTap: null,
                    leading: Icon(Icons.notifications_active_rounded,
                        color: read ? Colors.grey : Colors.indigo),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: read ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(body),
                    trailing: timestamp != null
                        ? Text(
                      _formatTimestamp(timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
