// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
//     'high_importance_channel',
//     'High Importance Notifications',
//     description: 'Used for chat messages and alerts',
//     importance: Importance.high,
//   );
//
//   /// 🔹 Initialize notifications
//   static Future<void> initialize() async {
//     const AndroidInitializationSettings androidInitSettings =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const InitializationSettings initSettings =
//     InitializationSettings(android: androidInitSettings);
//
//     await _notificationsPlugin.initialize(initSettings);
//
//     // Create the channel
//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(_channel);
//   }
//
//   /// 🔹 Display a simple notification
//   static Future<void> showNotification({
//     required String title,
//     required String body,
//   }) async {
//     await _notificationsPlugin.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
//       title,
//       body,
//       NotificationDetails(
//         android: AndroidNotificationDetails(
//           _channel.id,
//           _channel.name,
//           channelDescription: _channel.description,
//           importance: Importance.high,
//           priority: Priority.high,
//           icon: '@mipmap/ic_launcher',
//         ),
//       ),
//     );
//   }
// }
