// // import 'dart:convert';

// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// // class LocalNotificationService {
// //   final FlutterLocalNotificationsPlugin _plugin =
// //       FlutterLocalNotificationsPlugin();

// //   Future<void> initialize({
// //     required Function(String chatId, String senderId) onNotificationTap,
// //   }) async {
// //     const androidSettings =
// //         AndroidInitializationSettings('@mipmap/ic_launcher');

// //     const initializationSettings = InitializationSettings(
// //       android: androidSettings,
// //     );

// //     // await _plugin.initialize(
// //     //   initializationSettings,
// //     //   onDidReceiveNotificationResponse: (response) {
// //     //     final payload = response.payload;

// //     //     if (payload == null || payload.isEmpty) {
// //     //       return;
// //     //     }

// //     //     try {
// //     //       final data = jsonDecode(payload);

// //     //       final chatId = data['chatId']?.toString();
// //     //       final senderId = data['senderId']?.toString();

// //     //       if (chatId == null ||
// //     //           chatId.isEmpty ||
// //     //           senderId == null ||
// //     //           senderId.isEmpty) {
// //     //         return;
// //     //       }

// //     //       onNotificationTap(chatId, senderId);
// //     //     } catch (e) {
// //     //       print('Local notification payload error: $e');
// //     //     }
// //     //   },
// //     // );

// //     await _plugin.initialize(
// //   initializationSettings,
// //   onDidReceiveNotificationResponse: (NotificationResponse response) {
// //     final payload = response.payload;

// //     if (payload == null || payload.isEmpty) {
// //       return;
// //     }

// //     try {
// //       final data = jsonDecode(payload);

// //       final chatId = data['chatId']?.toString();
// //       final senderId = data['senderId']?.toString();

// //       if (chatId == null ||
// //           chatId.isEmpty ||
// //           senderId == null ||
// //           senderId.isEmpty) {
// //         return;
// //       }

// //       onNotificationTap(chatId, senderId);
// //     } catch (e) {
// //       print('Local notification payload error: $e');
// //     }
// //   },
// // );

// //     const channel = AndroidNotificationChannel(
// //       'chat_messages',
// //       'Chat Messages',
// //       description: 'Notifications for new chat messages',
// //       importance: Importance.high,
// //       playSound: true,
// //     );

// //     final androidPlugin =
// //         _plugin.resolvePlatformSpecificImplementation<
// //             AndroidFlutterLocalNotificationsPlugin>();

// //     await androidPlugin?.createNotificationChannel(channel);

// //     await androidPlugin?.requestNotificationsPermission();
// //   }

// //   Future<void> showMessageNotification({
// //     required String title,
// //     required String body,
// //     required String chatId,
// //     required String senderId,
// //   }) async {
// //     const androidDetails = AndroidNotificationDetails(
// //       'chat_messages',
// //       'Chat Messages',
// //       channelDescription: 'Notifications for new chat messages',
// //       importance: Importance.high,
// //       priority: Priority.high,
// //       playSound: true,
// //       enableVibration: true,
// //     );

// //     const notificationDetails = NotificationDetails(
// //       android: androidDetails,
// //     );

// //     final payload = jsonEncode({
// //       'chatId': chatId,
// //       'senderId': senderId,
// //     });

// //     await _plugin.show(
// //       DateTime.now().millisecondsSinceEpoch.remainder(100000),
// //       title,
// //       body,
// //       notificationDetails,
// //       payload: payload,
// //     );
// //   }
// // }

// import 'dart:convert';

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class LocalNotificationService {
//   final FlutterLocalNotificationsPlugin _plugin =
//       FlutterLocalNotificationsPlugin();

//   Future<void> initialize({
//     required Function(String chatId, String senderId) onNotificationTap,
//   }) async {
//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );

//     const initializationSettings = InitializationSettings(
//       android: androidSettings,
//     );

//     await _plugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         final payload = response.payload;

//         if (payload == null || payload.isEmpty) {
//           return;
//         }

//         try {
//           final Map<String, dynamic> data =
//               jsonDecode(payload) as Map<String, dynamic>;

//           final String? chatId = data['chatId']?.toString();
//           final String? senderId = data['senderId']?.toString();

//           if (chatId == null ||
//               chatId.isEmpty ||
//               senderId == null ||
//               senderId.isEmpty) {
//             return;
//           }

//           onNotificationTap(chatId, senderId);
//         } catch (e) {
//           print('Local notification payload error: $e');
//         }
//       },
//     );

//     const channel = AndroidNotificationChannel(
//       'chat_messages',
//       'Chat Messages',
//       description: 'Notifications for new chat messages',
//       importance: Importance.high,
//       playSound: true,
//     );

//     final androidPlugin =
//         _plugin.resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>();

//     await androidPlugin?.createNotificationChannel(channel);

//     await androidPlugin?.requestNotificationsPermission();
//   }

//   Future<void> showMessageNotification({
//     required String title,
//     required String body,
//     required String chatId,
//     required String senderId,
//   }) async {
//     const androidDetails = AndroidNotificationDetails(
//       'chat_messages',
//       'Chat Messages',
//       channelDescription: 'Notifications for new chat messages',
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       enableVibration: true,
//     );

//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//     );

//     final String payload = jsonEncode({
//       'chatId': chatId,
//       'senderId': senderId,
//     });

//     await _plugin.show(
//       DateTime.now().millisecondsSinceEpoch.remainder(100000),
//       title,
//       body,
//       notificationDetails,
//       payload: payload,
//     );
//   }
// }