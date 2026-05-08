import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/welcomenote.dart';
import 'package:peereess/screens/widgets/location.widget.dart';
import 'package:provider/provider.dart';

class Signupaddress extends StatefulWidget {
  const Signupaddress({super.key});

  @override
  State<Signupaddress> createState() => _SignupaddressState();
}

class _SignupaddressState extends State<Signupaddress> {
  final _formKey = GlobalKey<FormState>(); // ✅ ADD THIS

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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Form(
                // ✅ WRAP WITH FORM
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/home'),
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                    ),
                    30.getHeightWhiteSpacing,
                    const Text(
                      "Add a delivery information",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const LocationWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // ── BUTTON ─────────────────────────────
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: AppButtons(
              text: "Save address",
              onPressed: () async {
                // ✅ VALIDATE FIRST
                if (!_formKey.currentState!.validate()) {
                  return; // stop if invalid
                }

                final auth = context.read<AuthProvider>();

                try {
                  await auth.updateUserRow(
                    updateReceiverName: true,
                    updatePhoneCode: true,
                    updateDeliveryPhoneNumber: true,
                    updateState: true,
                    updateDeliveryAddress: true,
                  );

                  if (!context.mounted) return;

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        "Address Saved",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4A1B),
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 52,
                            color: Colors.brown,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Your delivery information has been saved successfully.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => WelcomeNotePage()));
                          },
                          child: const Text(
                            "OK",
                            style: TextStyle(color: Color(0xff9D6E2D)),
                          ),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        "Error",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4A1B),
                        ),
                      ),
                      content: Text(
                        "Failed to save address: $e",
                        style: const TextStyle(fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WelcomeNotePage())),
                          child: const Text(
                            "OK",
                            style: TextStyle(color: Color(0xff9D6E2D)),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
