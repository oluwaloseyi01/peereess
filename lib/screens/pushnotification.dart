import 'package:appwrite/appwrite.dart' hide Permission;
import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/app_images.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:permission_handler/permission_handler.dart';

class Pushnotification extends StatefulWidget {
  const Pushnotification({super.key});

  @override
  State<Pushnotification> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<Pushnotification> {
  // Function to request notification permission
  Future<void> requestNotificationPermission() async {
    // On Android < 13, permission is automatically granted
    // On iOS / Android 13+, this will request permission
    PermissionStatus status = await Permission.notification.request();

    if (status.isGranted) {
      print("Notification permission granted");
    } else {
      print("Notification permission denied");
    }

    // Navigate after asking
    Navigator.pushNamed(context, "/recomendscreen");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            30.getHeightWhiteSpacing,
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/recomendscreen'),
                child: const Text(
                  "Skip",
                  style: TextStyle(fontSize: 13, color: Colors.pinkAccent),
                ),
              ),
            ),
            150.getHeightWhiteSpacing,
            Padding(
              padding: const EdgeInsets.all(40),
              child: Image.asset(
                AppImages.pushnotification,
                fit: BoxFit.scaleDown,
              ),
            ),
            10.getHeightWhiteSpacing,
            const Text(
              "Push Notification Required",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            10.getHeightWhiteSpacing,
            const Text(
              "Some features will not work without push",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Text(
              "notification. You can always turn it off later",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: AppButtons(
              onPressed: () async {
                await requestNotificationPermission(); // Request permission
              },
              text: "Turn on",
            ),
          ),
        ),
      ),
    );
  }
}
