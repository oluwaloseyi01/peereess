import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/core/textanimation.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/privacypolicy.dart';
import 'package:peereess/screens/temsofuse.dart';
import 'package:peereess/screens/widgets/googlelogi.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  int _currentPage = 0;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  bool isObscurePass = true;
  bool isObscureConfirm = true;
  bool agreeTerms = false;

  String password = "";
  bool has8Chars = false;
  bool hasNumber = false;
  bool hasUpperLower = false;

  void validatePassword(String value) {
    password = value;
    setState(() {
      has8Chars = password.length >= 8;
      hasNumber = password.contains(RegExp(r'\d'));
      hasUpperLower = password.contains(RegExp(r'(?=.*[a-z])(?=.*[A-Z])'));
    });
  }

  void _nextPage(GlobalKey<FormState> key) {
    if (key.currentState!.validate()) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    setState(() => _currentPage--);
  }

  @override
  void dispose() {
    super.dispose();
  }

  double _maxWidth(double sw) {
    if (sw > 1200) return 450;
    if (sw > 600) return 500;
    return double.infinity;
  }

  double _hPad(double sw) {
    if (sw > 1200) return 24;
    if (sw > 600) return 20;
    return 12;
  }

  InputDecoration _inputDecor() => InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 124, 123, 123),
            width: 1,
          ),
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
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 2,
          ),
        ),
      );

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _currentPage;
        final isDone = i < _currentPage;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDone || isActive
                    ? const Color(0xffB0864C)
                    : Colors.grey.shade300,
              ),
            ),
            if (i < 2)
              Container(
                width: 24,
                height: 1.5,
                color: isDone ? const Color(0xffB0864C) : Colors.grey.shade300,
              ),
          ],
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PAGE 1 — Personal Info
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPage1(AuthProvider auth) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          20.getHeightWhiteSpacing,
          const Text(
            "Let's get to know you",
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            "Start with the basics.",
            style: TextStyle(
                color: Color.fromARGB(255, 138, 137, 137), fontSize: 12),
          ),
          16.getHeightWhiteSpacing,
          const Text(
            "Full Name",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          4.getHeightWhiteSpacing,
          TextFormField(
            controller: auth.fullNameController,
            validator: (v) {
              if (v == null || v.isEmpty) return "Full name is required";
              if (v.length < 3) return "Name must be at least 3 characters";
              return null;
            },
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecor(),
          ),
          10.getHeightWhiteSpacing,
          const Text(
            "Email Address",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          4.getHeightWhiteSpacing,
          TextFormField(
            controller: auth.emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return "Email is required";
              if (!v.contains("@") || !v.contains("."))
                return "Enter a valid email";
              return null;
            },
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecor(),
          ),
          10.getHeightWhiteSpacing,
          const Text(
            "Phone Number",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          4.getHeightWhiteSpacing,
          TextFormField(
            controller: auth.phoneNumberController,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return "Phone number is required";
              if (v.length < 10) return "Enter a valid phone number";
              return null;
            },
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecor(),
          ),
          20.getHeightWhiteSpacing,
          AppButtons(text: "Next", onPressed: () => _nextPage(_formKey1)),
          14.getHeightWhiteSpacing,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Already have an account?",
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, "/login"),
                child: const Text(
                  "Sign in",
                  style: TextStyle(
                    color: Color(0xffB0864C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          20.getHeightWhiteSpacing,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PAGE 2 — Password
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPage2(AuthProvider auth) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          20.getHeightWhiteSpacing,
          const Text(
            "Secure your account",
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            "Choose a strong password.",
            style: TextStyle(
                color: Color.fromARGB(255, 138, 137, 137), fontSize: 12),
          ),
          16.getHeightWhiteSpacing,
          const Text(
            "Password",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          4.getHeightWhiteSpacing,
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TextFormField(
                controller: auth.passwordController,
                obscureText: isObscurePass,
                onChanged: validatePassword,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Password is required";
                  if (!has8Chars || !hasNumber || !hasUpperLower)
                    return "Password does not meet safety rules";
                  return null;
                },
                style: const TextStyle(fontSize: 15),
                decoration: _inputDecor(),
              ),
              IconButton(
                icon: Icon(
                  isObscurePass ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => isObscurePass = !isObscurePass),
              ),
            ],
          ),
          6.getHeightWhiteSpacing,
          _ruleRow("At least 8 characters", has8Chars),
          _ruleRow("At least 1 number", hasNumber),
          _ruleRow("Both upper and lowercase", hasUpperLower),
          16.getHeightWhiteSpacing,
          const Text(
            "Confirm Password",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          4.getHeightWhiteSpacing,
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TextFormField(
                obscureText: isObscureConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Confirm your password";
                  if (v != auth.passwordController.text)
                    return "Passwords do not match";
                  return null;
                },
                style: const TextStyle(fontSize: 15),
                decoration: _inputDecor(),
              ),
              IconButton(
                icon: Icon(
                  isObscureConfirm ? Icons.visibility : Icons.visibility_off,
                  size: 18,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => isObscureConfirm = !isObscureConfirm),
              ),
            ],
          ),
          20.getHeightWhiteSpacing,
          Row(
            children: [
              Expanded(
                child: Appbuttons2(text: "Back", onPressed: _prevPage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButtons(
                  text: "Next",
                  onPressed: () => _nextPage(_formKey2),
                ),
              ),
            ],
          ),
          20.getHeightWhiteSpacing,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PAGE 3 — Terms & Confirm
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPage3(AuthProvider auth) {
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          20.getHeightWhiteSpacing,
          const Text(
            "Almost there!",
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            "Review and accept to create your account.",
            style: TextStyle(
                color: Color.fromARGB(255, 138, 137, 137), fontSize: 12),
          ),
          24.getHeightWhiteSpacing,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(
                  Icons.person_outline,
                  auth.fullNameController.text,
                ),
                const SizedBox(height: 10),
                _summaryRow(Icons.email_outlined, auth.emailController.text),
                const SizedBox(height: 10),
                _summaryRow(
                  Icons.phone_outlined,
                  auth.phoneNumberController.text,
                ),
                const SizedBox(height: 10),
                _summaryRow(Icons.lock_outline, "••••••••"),
              ],
            ),
          ),
          24.getHeightWhiteSpacing,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => agreeTerms = !agreeTerms),
                child: Container(
                  height: 15,
                  width: 15,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    border: Border.all(color: const Color(0xffB0864C)),
                    color: agreeTerms
                        ? const Color(0xffB0864C)
                        : Colors.transparent,
                  ),
                  child: agreeTerms
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  children: [
                    const Text(
                      "By clicking Continue, you accept our",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsofUse()),
                      ),
                      child: const Text(
                        " Terms of Service",
                        style: TextStyle(
                          color: Color(0xFF604520),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      " and",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Privacypolicy(),
                        ),
                      ),
                      child: const Text(
                        " Privacy Policy.",
                        style: TextStyle(
                          color: Color(0xFF604520),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          20.getHeightWhiteSpacing,
          Row(
            children: [
              Expanded(
                child: Appbuttons2(text: "Back", onPressed: _prevPage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButtons(
                  text: "Create Account",
                  onPressed: () {
                    if (!agreeTerms) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("You must accept terms to continue"),
                        ),
                      );
                      return;
                    }
                    auth.register(context);
                  },
                ),
              ),
            ],
          ),
          14.getHeightWhiteSpacing,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Already have an account?",
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, "/login"),
                child: const Text(
                  "Sign in",
                  style: TextStyle(
                    color: Color(0xffB0864C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          20.getHeightWhiteSpacing,
        ],
      ),
    );
  }

  Widget _ruleRow(String text, bool met) => Row(
        children: [
          Icon(
            Icons.check_circle,
            color: met ? Colors.green : Colors.grey,
            size: 10,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style:
                TextStyle(color: met ? Colors.green : Colors.grey, fontSize: 9),
          ),
        ],
      );

  Widget _summaryRow(IconData icon, String value) => Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xffB0864C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? "—" : value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sw = MediaQuery.of(context).size.width;

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
                      constraints: BoxConstraints(maxWidth: _maxWidth(sw)),
                      padding: EdgeInsets.symmetric(horizontal: _hPad(sw)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          50.getHeightWhiteSpacing,
                          AnimatedGradientText(
                            text: "Peereess",
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            fontFamily: "poppins",
                            gradientColors: const [
                              Color(0xFF604520),
                              Color(0xFFDD7394),
                            ],
                          ),
                          8.getHeightWhiteSpacing,
                          const Text(
                            "Let's make you a peereess member",
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          16.getHeightWhiteSpacing,
                          _buildStepIndicator(),
                          8.getHeightWhiteSpacing,

                          // ── PageView inside an intrinsic-height wrapper ──
                          // We use an AnimatedSize + IndexedStack so the height
                          // adjusts to whichever page is active, keeping the
                          // whole screen centred like Login.
                          AnimatedSize(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                            child: IndexedStack(
                              index: _currentPage,
                              children: [
                                _buildPage1(auth),
                                _buildPage2(auth),
                                _buildPage3(auth),
                              ],
                            ),
                          ),

                          50.getHeightWhiteSpacing,
                        ],
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
          ],
        ),
      ),
    );
  }
}
