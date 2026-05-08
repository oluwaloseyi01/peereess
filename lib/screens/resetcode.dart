import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/screens/resetpassword.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  bool isLoading = false;
  String message = '';

  int resendSeconds = 60;
  Timer? _timer;

  late final Client client;
  late final Functions functions;

  @override
  void initState() {
    super.initState();

    client = Client()
      ..setEndpoint('https://nyc.cloud.appwrite.io/v1')
      ..setProject('69383047001867cb050b');

    functions = Functions(client);

    _startCountdown();
  }

  void _startCountdown() {
    resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() => resendSeconds--);
        }
      }
    });
  }

  String get _otp => otpControllers.map((e) => e.text).join();

  // ✅ VERIFY OTP (FIXED SAFETY)
  Future<void> verifyOtp() async {
    if (_otp.length != 6) {
      _showSnack("Enter complete OTP");
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final exec = await functions.createExecution(
        functionId: '694af06c0019df7f3906',
        body: jsonEncode({
          "type": "passwordReset",
          "action": "verifyOtp",
          "email": widget.email,
          "otp": _otp,
        }),
      );

      final body = exec.responseBody ?? '';
      final resp = body.isNotEmpty ? jsonDecode(body) : null;

      if (!mounted) return;

      if (resp != null && resp['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP verified successfully")),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NewPasswordPage(email: widget.email, otp: _otp),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp?['message'] ?? "OTP verification failed"),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ RESEND OTP (FIXED SAFETY)
  Future<void> resendOtp() async {
    if (resendSeconds > 0) return;

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final exec = await functions.createExecution(
        functionId: '694af06c0019df7f3906',
        body: jsonEncode({
          "type": "passwordReset",
          "action": "sendOtp",
          "email": widget.email,
          "isFirstVerify": false,
        }),
      );

      final body = exec.responseBody ?? '';
      final resp = body.isNotEmpty ? jsonDecode(body) : null;

      if (!mounted) return;

      if (resp != null && resp['status'] == true) {
        _startCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Code resent successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp?['message'] ?? "Failed to resend code"),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in otpControllers) {
      c.dispose();
    }
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
            colors: [
              Color.fromARGB(255, 217, 194, 162),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter OTP",
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                10.getHeightWhiteSpacing,
                const Text(
                  "A reset verification code has been sent to:",
                  style: TextStyle(fontSize: 13),
                ),
                Text(widget.email),
                20.getHeightWhiteSpacing,
                Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 55,
                        child: TextField(
                          controller: otpControllers[i],
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              FocusScope.of(context).nextFocus();
                            }
                            if (v.isEmpty && i > 0) {
                              FocusScope.of(context).previousFocus();
                            }
                          },
                          decoration: InputDecoration(
                            counterText: "",
                            filled: true,
                            fillColor: const Color(0xffF5F5F5),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                20.getHeightWhiteSpacing,
                Center(
                  child: TextButton(
                    onPressed: resendSeconds == 0 ? resendOtp : null,
                    child: Text(
                      resendSeconds == 0
                          ? "Resend OTP"
                          : "Resend in $resendSeconds s",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: AppButtons(
              text: isLoading ? "Please wait..." : "Continue",
              onPressed: verifyOtp,
            ),
          ),
        ),
      ),
    );
  }
}
