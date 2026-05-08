import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/screens/login.dart';

class NewPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const NewPasswordPage({super.key, required this.email, required this.otp});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  bool _obscurePassword = true;
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  late final Client client;
  late final Functions functions;

  // ✅ RULE STATES
  bool has8Chars = false;
  bool hasNumber = false;
  bool hasUpperLower = false;

  bool get isPasswordValid => has8Chars && hasNumber && hasUpperLower;

  @override
  void initState() {
    super.initState();

    client = Client()
      ..setEndpoint('https://nyc.cloud.appwrite.io/v1')
      ..setProject('69383047001867cb050b');

    functions = Functions(client);

    passwordController.addListener(_checkPasswordRules);
  }

  void _checkPasswordRules() {
    final password = passwordController.text;

    setState(() {
      has8Chars = password.length >= 8;
      hasNumber = RegExp(r'\d').hasMatch(password);
      hasUpperLower = RegExp(r'[A-Z]').hasMatch(password) &&
          RegExp(r'[a-z]').hasMatch(password);
    });
  }

  Future<void> resetPassword() async {
    if (!isPasswordValid) return; // ✅ BLOCK IF INVALID

    setState(() => isLoading = true);

    try {
      final exec = await functions.createExecution(
        functionId: '694af06c0019df7f3906',
        body: jsonEncode({
          "type": "passwordReset",
          "action": "resetPassword",
          "email": widget.email,
          "otp": widget.otp,
          "new_password": passwordController.text.trim(),
        }),
      );

      final body = exec.responseBody ?? '';
      final resp = body.isNotEmpty ? jsonDecode(body) : null;

      if (!mounted) return;

      if (resp != null && resp['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset successful")),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp?['message'] ?? "Failed to reset password"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _ruleRow(String text, bool met) => Row(
        children: [
          Icon(
            Icons.check_circle,
            color: met ? Colors.green : Colors.grey,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: met ? Colors.green : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      );

  @override
  void dispose() {
    passwordController.removeListener(_checkPasswordRules);
    passwordController.dispose();
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
                "New Password",
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              10.getHeightWhiteSpacing,
              Text(
                "Set a new password for ",
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              20.getHeightWhiteSpacing,
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _ruleRow("At least 8 characters", has8Chars),
              const SizedBox(height: 4),
              _ruleRow("At least 1 number", hasNumber),
              const SizedBox(height: 4),
              _ruleRow("Both upper and lowercase", hasUpperLower),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: AppButtons(
              text: isLoading ? "Please wait..." : "Complete",
              onPressed: resetPassword,
            ),
          ),
        ),
      ),
    );
  }
}
