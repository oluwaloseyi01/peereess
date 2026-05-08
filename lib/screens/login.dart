import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/core/textanimation.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/forgetpassword.dart';
import 'package:peereess/screens/widgets/googlelogi.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formKey = GlobalKey<FormState>();
  bool isObscurePass = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    double getMaxWidth() {
      if (screenWidth > 1200) return 450;
      if (screenWidth > 600) return 500;
      return double.infinity;
    }

    double getHorizontalPadding() {
      if (screenWidth > 1200) return 24;
      if (screenWidth > 600) return 20;
      return 12;
    }

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
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: getMaxWidth()),
                      child: Padding(
                        padding: EdgeInsets.all(getHorizontalPadding()),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              50.getHeightWhiteSpacing,
                              Align(
                                alignment: Alignment.center,
                                child: AnimatedGradientText(
                                  text: "Peereess",
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: "poppins",
                                  gradientColors: const [
                                    Color(0xFF604520),
                                    Color(0xFFDD7394),
                                  ],
                                ),
                              ),
                              10.getHeightWhiteSpacing,
                              const Text(
                                "Welcome back",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              10.getHeightWhiteSpacing,
                              const Text(
                                "Email",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              TextFormField(
                                controller: auth.emailController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Email is required";
                                  }
                                  if (!value.contains("@") ||
                                      !value.contains(".")) {
                                    return "Enter a valid email";
                                  }
                                  return null;
                                },
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 10,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color.fromARGB(255, 232, 142, 172),
                                      width: 2,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              15.getHeightWhiteSpacing,
                              const Text(
                                "Password",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  TextFormField(
                                    controller: auth.passwordController,
                                    obscureText: isObscurePass,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Password is required";
                                      }
                                      if (value.length < 6) {
                                        return "Password must not be less than 6 characters";
                                      }
                                      return null;
                                    },
                                    style: const TextStyle(fontSize: 15),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 10,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            232,
                                            142,
                                            172,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isObscurePass
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(
                                      () => isObscurePass = !isObscurePass,
                                    ),
                                  ),
                                ],
                              ),
                              5.getHeightWhiteSpacing,
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ForgotPasswordPage(),
                                    ),
                                  ),
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Color(0xffB0864C),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              20.getHeightWhiteSpacing,
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return AppButtons(
                                    text: "Sign in",
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        auth.login(context);
                                      }
                                    },
                                  );
                                },
                              ),
                              // 16.getHeightWhiteSpacing,

                              // // ── Divider ──────────────────────────
                              // Row(
                              //   children: [
                              //     Expanded(
                              //       child: Divider(
                              //         color: Colors.grey.shade400,
                              //         thickness: 0.8,
                              //       ),
                              //     ),
                              //     Padding(
                              //       padding: const EdgeInsets.symmetric(
                              //         horizontal: 10,
                              //       ),
                              //       child: Text(
                              //         "or",
                              //         style: TextStyle(
                              //           color: Colors.grey.shade500,
                              //           fontSize: 12,
                              //         ),
                              //       ),
                              //     ),
                              //     Expanded(
                              //       child: Divider(
                              //         color: Colors.grey.shade400,
                              //         thickness: 0.8,
                              //       ),
                              //     ),
                              //   ],
                              // ),

                              // 12.getHeightWhiteSpacing,

                              // // ── Google Sign In Button ─────────────
                              // Consumer<AuthProvider>(
                              //   builder: (context, auth, _) {
                              //     return GoogleButton(
                              //       onPressed: () => auth.googleSignIn(context),
                              //     );
                              //   },
                              // ),

                              10.getHeightWhiteSpacing,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "First time here?",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(width: 5),
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, "/signup"),
                                    child: const Text(
                                      "Create account",
                                      style: TextStyle(
                                        color: Color(0xffB0864C),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              50.getHeightWhiteSpacing,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (auth.isLoading)
              Container(
                color: Colors.black45,
                child: const Center(child: LogoLoadingIndicator()),
              ),
            if (!auth.isConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const SafeArea(
                    child: Center(
                      child: Text(
                        "No internet connection",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
