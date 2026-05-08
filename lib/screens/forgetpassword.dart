import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/screens/resetcode.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  String message = '';

  late final Client client;
  late final Functions functions;

  @override
  void initState() {
    super.initState();
    client = Client()
      ..setEndpoint('https://nyc.cloud.appwrite.io/v1')
      ..setProject('69383047001867cb050b');

    functions = Functions(client);
  }

  Future<void> sendResetCode() async {
    if (!formKey.currentState!.validate()) return;

    final email = emailController.text.trim();

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await functions.createExecution(
        functionId: '694af06c0019df7f3906',
        body: jsonEncode({
          "type": "passwordReset",
          "action": "sendOtp",
          "email": email,
          "isFirstVerify": false,
        }),
      );

      final body = result.responseBody ?? '';
      if (body.isEmpty) {
        setState(() => message = '❌ Empty response from server.');
        return;
      }

      final response = jsonDecode(body);

      if (response['status'] == true) {
        setState(() => message = '✅ OTP sent! Check your email.');

        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OtpVerificationPage(email: email)),
        );
      } else {
        setState(() {
          message =
              '❌ Failed to send OTP.\n${response['message'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() => message = '❌ Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: Color(0xff9D6E2D),
                ),
              ),
            ),
            10.getWidthWhiteSpacing,
          ],
        ),
      ),
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
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Forget Password?",
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              10.getHeightWhiteSpacing,
              const Text(
                "Enter your registered email to receive a password reset OTP.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Email address",
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 232, 142, 172),
                        width: 2,
                      ), // pink on focus
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(
                    color: message.startsWith('✅') ? Colors.green : Colors.red,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ),

      // ✅ Single bottom button
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: AppButtons(
              text: isLoading ? "Sending..." : "Continue",
              onPressed: sendResetCode,
            ),
          ),
        ),
      ),
    );
  }
}
