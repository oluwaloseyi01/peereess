import 'dart:async';

import 'package:flutter/material.dart';
import 'package:peereess/provider/verifyemailsignup.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';

import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/provider/auth_provider.dart';

class Verifyemail extends StatefulWidget {
  const Verifyemail({super.key});

  @override
  State<Verifyemail> createState() => _VerifyemailState();
}

class _VerifyemailState extends State<Verifyemail> {
  late AuthProvider authProvider;

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int secondsLeft = 120;
  bool canResend = false;
  bool isLoading = false;
  String? error;

  String email = '';
  String password = '';
  bool _argsLoaded = false;

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args == null) {
        debugPrint('❌ Verifyemail: no route arguments received');
        if (mounted) Navigator.pop(context);
        return;
      }

      setState(() {
        email = args['email'] ?? '';
        password = args['password'] ?? '';
        _argsLoaded = true;
      });

      debugPrint('✅ Verifyemail: email=$email');
      startTimer();
    });
  }

  @override
  void dispose() {
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var f in otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    secondsLeft = 120;
    canResend = false;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft <= 0) {
        setState(() => canResend = true);
        timer.cancel();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  String get timerText {
    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  String get otp => otpControllers.map((c) => c.text.trim()).join();

  Future<void> verifyOtp() async {
    if (otp.length != 6) {
      setState(() => error = "Enter valid code");
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final success = await EmailVerificationService.verifyOtp(email, otp);

      if (!success) {
        setState(() => error = "Invalid or expired code");
        return;
      }

      await AppwriteConfig.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      await authProvider.completeRegistration(context);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/emailverifysplash",
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => error = "Verification failed: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> resendOtp() async {
    if (!canResend) return;

    setState(() => isLoading = true);

    try {
      await EmailVerificationService.sendOtp(email);
      startTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent successfully")),
        );
      }
    } catch (e) {
      setState(() => error = "Failed to resend OTP");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_argsLoaded) {
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
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: AppButtons(onPressed: verifyOtp, text: "Continue"),
          ),
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
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main scrollable content ──
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, "/login"),
                      icon: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xffB0864C)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.arrow_back,
                            color: Color(0xffB0864C),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    20.getHeightWhiteSpacing,
                    const Text(
                      "Enter email verification code",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                    ),
                    12.getHeightWhiteSpacing,
                    const Text(
                      "A verification code has been sent to your email",
                      style: TextStyle(
                          color: Color.fromARGB(255, 138, 137, 137),
                          fontSize: 13),
                    ),
                    4.getHeightWhiteSpacing,
                    Text(email,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    36.getHeightWhiteSpacing,

                    // ── OTP boxes ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width:
                              (MediaQuery.of(context).size.width - 36 - 30) / 6,
                          height: 56,
                          child: TextField(
                            controller: otpControllers[i],
                            focusNode: otpFocusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff3D2B10),
                            ),
                            onChanged: (v) {
                              if (v.isNotEmpty) {
                                if (i < 5) {
                                  otpFocusNodes[i + 1].requestFocus();
                                } else {
                                  otpFocusNodes[i].unfocus();
                                }
                              } else if (v.isEmpty && i > 0) {
                                otpFocusNodes[i - 1].requestFocus();
                              }
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              counterText: "",
                              filled: true,
                              fillColor: otpControllers[i].text.isNotEmpty
                                  ? const Color(0xffF5EDE0)
                                  : Colors.white,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: otpControllers[i].text.isNotEmpty
                                      ? const Color(0xffB0864C)
                                      : const Color(0xffDDDDDD),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xffB0864C),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    28.getHeightWhiteSpacing,

                    // ── Resend ──
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't get the email?",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: resendOtp,
                                child: Text(
                                  "Resend",
                                  style: TextStyle(
                                    color: canResend
                                        ? const Color(0xffB0864C)
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          8.getHeightWhiteSpacing,
                          Text(
                            canResend
                                ? "You can resend now"
                                : "Resend code in $timerText",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Error ──
                    if (error != null) ...[
                      15.getHeightWhiteSpacing,
                      Center(
                        child: Text(
                          error!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Loading overlay — sits on top, matches gradient, no black ──
              if (isLoading)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(200, 217, 194, 162),
                        Color.fromARGB(200, 255, 255, 255),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(child: LogoLoadingIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
