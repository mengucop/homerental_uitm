import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'login_page.dart';
import 'admin/admin_home_page.dart'; // ✅ NEW

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background message received: ${message.notification?.title}");

  final title = message.notification?.title ?? 'Notification';
  final body = message.notification?.body ?? '';

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(user.uid)
        .collection('items')
        .add({
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  await setupFCM();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ Notifications authorized');
  } else {
    print('❌ Notifications denied or not granted');
  }

  final token = await messaging.getToken();
  print('📲 FCM Token: $token');

  final user = FirebaseAuth.instance.currentUser;
  if (user != null && token != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
    print('✅ FCM token saved to Firestore');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(user.uid)
            .collection('items')
            .add({
          'title': title,
          'body': body,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      final context = _navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title: $body'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 App opened from notification: ${message.notification?.title}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'HomeRentalUiTM',
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      home: FutureBuilder<User?>(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const LoginPage();
          } else if (user.email == 'admin@uitm.edu.my') {
            return const AdminHomePage(); // ✅ Redirect if admin
          } else {
            return const LoginPage(); // 🔁 or change this to UserHomePage()
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String errorMessage;
  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Startup Error")),
        body: Center(child: Text("Firebase Init Error:\n$errorMessage")),
      ),
    );
  }
}
