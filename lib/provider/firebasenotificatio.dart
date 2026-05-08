// import 'package:firebase_messaging/firebase_messaging.dart';

// Future<void> requestPushPermission() async {
//   FirebaseMessaging messaging = FirebaseMessaging.instance;

//   NotificationSettings settings = await messaging.requestPermission(
//     alert: true,
//     badge: true,
//     sound: true,
//   );

//   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//     print('User granted permission');
//   } else {
//     print('User declined or has not accepted permission');
//   }
// }
