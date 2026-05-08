import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class Deleteaccount extends StatefulWidget {
  const Deleteaccount({super.key});

  @override
  State<Deleteaccount> createState() => _DeleteaccountState();
}

class _DeleteaccountState extends State<Deleteaccount> {
  bool agreeTerms = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDeleting = authProvider.isLoading;

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
            const Text(
              "Delete Account",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
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
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 233, 226, 226),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const Text(
                        "Are you sure?",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "This action cannot be undone. Deleting your account will:",
                      ),
                      5.getHeightWhiteSpacing,
                      _bullet("Permanently delete all your personal data"),
                      _bullet("Remove your order history and saved items"),
                      _bullet("Cancel any active subscriptions"),
                      _bullet("Disable your login credentials"),
                      _bullet("Remove your reviews and ratings"),
                    ],
                  ),
                ),

                30.getHeightWhiteSpacing,

                /// TERMS CHECKBOX
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => agreeTerms = !agreeTerms),
                      child: Container(
                        height: 16,
                        width: 16,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffB0864C)),
                          color: agreeTerms
                              ? const Color(0xffB0864C)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    10.getWidthWhiteSpacing,
                    const Expanded(
                      child: Text(
                        "By clicking Delete Account, you accept our Terms of Service and Privacy Policy.",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                15.getHeightWhiteSpacing,

                /// DELETE BUTTON
                GestureDetector(
                  onTap: isDeleting
                      ? null
                      : () async {
                          if (!agreeTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please accept the terms before continuing",
                                ),
                              ),
                            );
                            return;
                          }

                          await context.read<AuthProvider>().deleteAccount(
                                context,
                              );
                        },
                  child: Container(
                    height: 45,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.red,
                    ),
                    child: Center(
                      child: isDeleting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Delete Account",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                10.getHeightWhiteSpacing,

                /// CANCEL
                Appbuttons2(
                  onPressed: () => Navigator.pop(context),
                  text: "Cancel",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// BULLET ROW
  Widget _bullet(String text) {
    return Row(
      children: [
        const Icon(Icons.circle, color: Colors.red, size: 8),
        6.getWidthWhiteSpacing,
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}
