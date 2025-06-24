import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BroadcastNotificationPage extends StatefulWidget {
  const BroadcastNotificationPage({super.key});

  @override
  State<BroadcastNotificationPage> createState() => _BroadcastNotificationPageState();
}

class _BroadcastNotificationPageState extends State<BroadcastNotificationPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool isSending = false;

  Future<void> _sendNotificationToAllUsers() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and body')),
      );
      return;
    }

    setState(() => isSending = true);

    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

      for (final doc in usersSnapshot.docs) {
        final token = doc['fcmToken'];
        if (token != null && token.toString().isNotEmpty) {
          // 🔔 Send to FCM
          await _sendFCM(token, title, body);

          // 💾 Save to user's notification list
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(doc.id)
              .collection('items')
              .add({
            'title': title,
            'body': body,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📢 Broadcast sent to all users')),
      );

      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to send: $e')),
      );
    } finally {
      setState(() => isSending = false);
    }
  }

  Future<void> _sendFCM(String token, String title, String body) async {
    const serverKey = 'BFhhPMoDieqg7xCl49NfPyarsSlMtqUrOaXWtyOnluQSquvvZmDFIQYCe3ZCgaJCJUP44biRfmsK16YHcbsvpfI'; // 🔐 Replace with your FCM server key

    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📢 Send Broadcast")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isSending ? null : _sendNotificationToAllUsers,
              icon: const Icon(Icons.send),
              label: isSending ? const Text("Sending...") : const Text("Send Broadcast"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
