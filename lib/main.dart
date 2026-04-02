import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nextalk/screens/login_screen.dart';
import 'package:nextalk/screens/home_screen.dart';
import 'package:nextalk/services/notification_service.dart'; // <- your local notifications service
import 'firebase_options.dart';

/// Background message handler (for messages received when app is terminated)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // await NotificationService.showNotification(
  //   title: message.notification?.title ?? 'New message',
  //   body: message.notification?.body ?? '',
  // );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate App Check in debug mode
  await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug);

  // Initialize local notifications
  // await NotificationService.initialize();

  // Firebase Messaging setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions on Android/iOS
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Optional: print token
  String? token = await messaging.getToken();
  print('FCM Token: $token');

  // Foreground message listener
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   if (message.notification != null) {
  //     NotificationService.showNotification(
  //       title: message.notification!.title ?? 'New message',
  //       body: message.notification!.body ?? '',
  //     );
  //   }
  // });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasData) {
          return MaterialApp(
            title: 'ChatPal',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.system,
            home: HomeScreen(),
          );
        }

        return MaterialApp(
          title: 'ChatPal',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.system,
          home: LoginScreen(),
        );
      },
    );
  }
}
