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

                              // ── Brand ─────────────────────────────
                              Align(
                                alignment: Alignment.center,
                                child: AnimatedGradientText(
                                  text: "Peereess",
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "poppins",
                                  gradientColors: const [
                                    Color(0xFF604520),
                                    Color(0xFFDD7394),
                                  ],
                                ),
                              ),

                              // ── Tagline ───────────────────────────
                              30.getHeightWhiteSpacing,

                              // ── Heading ───────────────────────────
                              const Text(
                                "Welcome back",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'poppins',
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C1A0E),
                                ),
                              ),

                              6.getHeightWhiteSpacing,

                              // ── Sub-heading ───────────────────────
                              Text(
                                "Sign in to continue your shopping journey.",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'poppins',
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),

                              22.getHeightWhiteSpacing,

                              // ── Email label ───────────────────────
                              const Text(
                                "Email address",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: 'poppins',
                                ),
                              ),
                              4.getHeightWhiteSpacing,
                              TextFormField(
                                controller: auth.emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Enter your Email";
                                  }
                                  if (!value.contains("@") ||
                                      !value.contains(".")) {
                                    return "Enter a valid email";
                                  }
                                  return null;
                                },
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'poppins',
                                ),
                                decoration: InputDecoration(
                                  hintText: "Email address",
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
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

                              18.getHeightWhiteSpacing,

                              // ── Password label ────────────────────
                              const Text(
                                "Password",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: 'poppins',
                                ),
                              ),
                              4.getHeightWhiteSpacing,
                              Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  TextFormField(
                                    controller: auth.passwordController,
                                    obscureText: isObscurePass,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Enter your password";
                                      }
                                      if (value.length < 4) {
                                        return "Password must be at least 5 characters";
                                      }
                                      return null;
                                    },
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'poppins',
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "*********",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13,
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
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
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isObscurePass
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => setState(
                                      () => isObscurePass = !isObscurePass,
                                    ),
                                  ),
                                ],
                              ),

                              6.getHeightWhiteSpacing,

                              // ── Forgot password ───────────────────
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
                                    "Forgot your password?",
                                    style: TextStyle(
                                      color: Color(0xffB0864C),
                                      fontSize: 12,
                                      fontFamily: 'poppins',
                                    ),
                                  ),
                                ),
                              ),

                              24.getHeightWhiteSpacing,

                              // ── Sign in button ────────────────────
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

                              20.getHeightWhiteSpacing,

                              // ── Divider ───────────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.shade300,
                                      thickness: 0.8,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      "New to Peereess?",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                        fontFamily: 'poppins',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey.shade300,
                                      thickness: 0.8,
                                    ),
                                  ),
                                ],
                              ),

                              14.getHeightWhiteSpacing,

                              // ── Create account ────────────────────
                              Center(
                                child: GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, "/signup"),
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontFamily: 'poppins',
                                        fontSize: 13,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "Don't have an account? ",
                                          style: TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "Create Account",
                                          style: TextStyle(
                                            color: Color(0xffB0864C),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              16.getHeightWhiteSpacing,

                              // ── Trust line ────────────────────────
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

            // ── Loading overlay ──────────────────────
            if (auth.isLoading)
              Container(
                color: Colors.black45,
                child: const Center(child: LogoLoadingIndicator()),
              ),

            // ── No connection banner ─────────────────
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
                          fontFamily: 'poppins',
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
