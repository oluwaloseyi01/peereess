import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:peereess/databases/activitylogout.dart';
import 'package:peereess/databases/config/sessionmanagement.dart';
import 'package:peereess/databases/routeguard.dart';
import 'package:peereess/firebase_options.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/provider.dart';
import 'package:peereess/provider/notificationservice.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FLUTTER ERROR: ${details.exception}');
    debugPrint('🔴 STACK: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 PLATFORM ERROR: $error');
    debugPrint('🔴 STACK: $stack');
    return true;
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('🔴 Init error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ...AppProvider().providers,
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ],
      child: const Peereess(),
    ),
  );

  try {
    await AppNotificationService.init(
      navigatorKey: SessionManager.navigatorKey,
    );
  } catch (e) {
    debugPrint('🔴 Notification init error: $e');
  }
}

class Peereess extends StatelessWidget {
  const Peereess({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peereess',
      debugShowCheckedModeBanner: false,
      navigatorKey: SessionManager.navigatorKey,
      initialRoute: '/',
      onGenerateRoute: RouteGuard.generateRoute,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      builder: (context, child) {
        return InactivityWrapper(child: child ?? const SizedBox());
      },
    );
  }
}
