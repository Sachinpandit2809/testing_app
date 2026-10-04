// // import 'dart:async';

// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';

// // class NotificationService {
// //   final FirebaseMessaging _messaging =
// //       FirebaseMessaging.instance;

// //   final FirebaseFirestore _firestore =
// //       FirebaseFirestore.instance;

// //   StreamSubscription<RemoteMessage>?
// //       _messageSubscription;

// //   StreamSubscription<RemoteMessage>?
// //       _messageOpenedSubscription;

// //   StreamSubscription<String>?
// //       _tokenRefreshSubscription;

// //   Future<void> initialize({
// //     required String userId,
// //     required Function(String chatId)
// //         onNotificationTap,
// //   }) async {
// //     await _requestPermission();

// //     await _saveCurrentToken(userId);

// //     _listenForTokenRefresh(userId);

// //     _listenForForegroundMessages();

// //     _listenForNotificationTap(
// //       onNotificationTap,
// //     );

// //     await _handleInitialMessage(
// //       onNotificationTap,
// //     );
// //   }

// //   Future<void> _requestPermission() async {
// //     final settings =
// //         await _messaging.requestPermission(
// //       alert: true,
// //       badge: true,
// //       sound: true,
// //       announcement: false,
// //       carPlay: false,
// //       criticalAlert: false,
// //       provisional: false,
// //     );

// //     print(
// //       'Notification permission: '
// //       '${settings.authorizationStatus}',
// //     );
// //   }

// //   Future<void> _saveCurrentToken(
// //     String userId,
// //   ) async {
// //     try {
// //       final token =
// //           await _messaging.getToken();

// //       if (token == null ||
// //           token.isEmpty) {
// //         return;
// //       }

// //       await _addToken(
// //         userId,
// //         token,
// //       );
// //     } catch (e) {
// //       print(
// //         'FCM token error: $e',
// //       );
// //     }
// //   }

// //   void _listenForTokenRefresh(
// //     String userId,
// //   ) {
// //     _tokenRefreshSubscription?.cancel();

// //     _tokenRefreshSubscription =
// //         _messaging.onTokenRefresh.listen(
// //       (token) async {
// //         await _addToken(
// //           userId,
// //           token,
// //         );
// //       },
// //     );
// //   }

// //   Future<void> _addToken(
// //     String userId,
// //     String token,
// //   ) async {
// //     await _firestore
// //         .collection('users')
// //         .doc(userId)
// //         .set(
// //       {
// //         'fcmTokens':
// //             FieldValue.arrayUnion([
// //           token,
// //         ]),
// //       },
// //       SetOptions(
// //         merge: true,
// //       ),
// //     );
// //   }

// //   void _listenForForegroundMessages() {
// //     _messageSubscription?.cancel();

// //     _messageSubscription =
// //         FirebaseMessaging.onMessage.listen(
// //       (RemoteMessage message) {
// //         print(
// //           'Foreground notification: '
// //           '${message.data}',
// //         );

// //         // We will handle a local notification
// //         // here in the next step.
// //       },
// //     );
// //   }

// //   void _listenForNotificationTap(
// //     Function(String chatId)
// //         onNotificationTap,
// //   ) {
// //     _messageOpenedSubscription
// //         ?.cancel();

// //     _messageOpenedSubscription =
// //         FirebaseMessaging
// //             .onMessageOpenedApp
// //             .listen(
// //       (RemoteMessage message) {
// //         final chatId =
// //             message.data['chatId'];

// //         if (chatId != null &&
// //             chatId.toString().isNotEmpty) {
// //           onNotificationTap(
// //             chatId.toString(),
// //           );
// //         }
// //       },
// //     );
// //   }

// //   Future<void> _handleInitialMessage(
// //     Function(String chatId)
// //         onNotificationTap,
// //   ) async {
// //     final message =
// //         await _messaging
// //             .getInitialMessage();

// //     if (message == null) {
// //       return;
// //     }

// //     final chatId =
// //         message.data['chatId'];

// //     if (chatId != null &&
// //         chatId.toString().isNotEmpty) {
// //       onNotificationTap(
// //         chatId.toString(),
// //       );
// //     }
// //   }

// //   Future<void> removeToken(
// //     String userId,
// //   ) async {
// //     try {
// //       final token =
// //           await _messaging.getToken();

// //       if (token == null) {
// //         return;
// //       }

// //       await _firestore
// //           .collection('users')
// //           .doc(userId)
// //           .set(
// //         {
// //           'fcmTokens':
// //               FieldValue.arrayRemove([
// //             token,
// //           ]),
// //         },
// //         SetOptions(
// //           merge: true,
// //         ),
// //       );
// //     } catch (e) {
// //       print(
// //         'Remove FCM token error: $e',
// //       );
// //     }
// //   }

// //   Future<void> dispose() async {
// //     await _messageSubscription
// //         ?.cancel();

// //     await _messageOpenedSubscription
// //         ?.cancel();

// //     await _tokenRefreshSubscription
// //         ?.cancel();
// //   }
// // }

// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// import 'local_notification_service.dart';

// class NotificationService {
//   final FirebaseMessaging _messaging =
//       FirebaseMessaging.instance;

//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   final LocalNotificationService _localNotificationService =
//       LocalNotificationService();

//   StreamSubscription<RemoteMessage>? _messageSubscription;
//   StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
//   StreamSubscription<String>? _tokenRefreshSubscription;

//   Future<void> initialize({
//     required String userId,
//     required Function(String chatId, String senderId)
//         onNotificationTap,
//   }) async {
//     await _requestPermission();

//     await _localNotificationService.initialize(
//       onNotificationTap: onNotificationTap,
//     );

//     await _saveCurrentToken(userId);

//     _listenForTokenRefresh(userId);

//     _listenForForegroundMessages();

//     _listenForNotificationTap(onNotificationTap);

//     await _handleInitialMessage(onNotificationTap);
//   }

//   Future<void> _requestPermission() async {
//     final settings = await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//       announcement: false,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//     );

//     print(
//       'Notification permission: '
//       '${settings.authorizationStatus}',
//     );
//   }

//   Future<void> _saveCurrentToken(String userId) async {
//     try {
//       final token = await _messaging.getToken();

//       if (token == null || token.isEmpty) {
//         return;
//       }

//       await _addToken(userId, token);

//       print('FCM token saved');
//     } catch (e) {
//       print('FCM token error: $e');
//     }
//   }

//   void _listenForTokenRefresh(String userId) {
//     _tokenRefreshSubscription?.cancel();

//     _tokenRefreshSubscription =
//         _messaging.onTokenRefresh.listen((token) async {
//       try {
//         await _addToken(userId, token);

//         print('FCM token refreshed');
//       } catch (e) {
//         print('FCM token refresh error: $e');
//       }
//     });
//   }

//   Future<void> _addToken(
//     String userId,
//     String token,
//   ) async {
//     await _firestore
//         .collection('users')
//         .doc(userId)
//         .set(
//       {
//         'fcmTokens': FieldValue.arrayUnion([token]),
//       },
//       SetOptions(merge: true),
//     );
//   }

//   void _listenForForegroundMessages() {
//     _messageSubscription?.cancel();

//     _messageSubscription =
//         FirebaseMessaging.onMessage.listen((message) async {
//       print('Foreground FCM message received');
//       print('Data: ${message.data}');

//       final notification = message.notification;

//       if (notification == null) {
//         return;
//       }

//       final title = notification.title ?? 'New Message';
//       final body = notification.body ?? '';

//       final chatId =
//           message.data['chatId']?.toString() ?? '';

//       final senderId =
//           message.data['senderId']?.toString() ?? '';

//       if (chatId.isEmpty || senderId.isEmpty) {
//         return;
//       }

//       await _localNotificationService.showMessageNotification(
//         title: title,
//         body: body,
//         chatId: chatId,
//         senderId: senderId,
//       );
//     });
//   }

//   void _listenForNotificationTap(
//     Function(String chatId, String senderId)
//         onNotificationTap,
//   ) {
//     _messageOpenedSubscription?.cancel();

//     _messageOpenedSubscription =
//         FirebaseMessaging.onMessageOpenedApp.listen(
//       (RemoteMessage message) {
//         print('Notification tapped from background');

//         final chatId =
//             message.data['chatId']?.toString();

//         final senderId =
//             message.data['senderId']?.toString();

//         if (chatId == null ||
//             chatId.isEmpty ||
//             senderId == null ||
//             senderId.isEmpty) {
//           return;
//         }

//         onNotificationTap(chatId, senderId);
//       },
//     );
//   }

//   Future<void> _handleInitialMessage(
//     Function(String chatId, String senderId)
//         onNotificationTap,
//   ) async {
//     final message =
//         await _messaging.getInitialMessage();

//     if (message == null) {
//       return;
//     }

//     print('Notification opened app from terminated state');

//     final chatId =
//         message.data['chatId']?.toString();

//     final senderId =
//         message.data['senderId']?.toString();

//     if (chatId == null ||
//         chatId.isEmpty ||
//         senderId == null ||
//         senderId.isEmpty) {
//       return;
//     }

//     onNotificationTap(chatId, senderId);
//   }

//   Future<void> removeToken(String userId) async {
//     try {
//       final token = await _messaging.getToken();

//       if (token == null || token.isEmpty) {
//         return;
//       }

//       await _firestore
//           .collection('users')
//           .doc(userId)
//           .set(
//         {
//           'fcmTokens': FieldValue.arrayRemove([token]),
//         },
//         SetOptions(merge: true),
//       );

//       print('FCM token removed');
//     } catch (e) {
//       print('Remove FCM token error: $e');
//     }
//   }

//   Future<void> dispose() async {
//     await _messageSubscription?.cancel();
//     await _messageOpenedSubscription?.cancel();
//     await _tokenRefreshSubscription?.cancel();

//     _messageSubscription = null;
//     _messageOpenedSubscription = null;
//     _tokenRefreshSubscription = null;
//   }
// }