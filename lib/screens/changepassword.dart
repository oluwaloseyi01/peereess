import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool hasNumber = false;
  bool hasUpperLower = false;
  bool hasMinLength = false;

  @override
  void initState() {
    super.initState();
    newPasswordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = newPasswordController.text;
    setState(() {
      hasNumber = RegExp(r'\d').hasMatch(password);
      hasUpperLower = RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(password);
      hasMinLength = password.length >= 8;
    });
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New password and confirm password do not match"),
        ),
      );
      return;
    }

    if (!(hasNumber && hasUpperLower && hasMinLength)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password does not meet the requirements"),
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      // Update password directly using old password
      await authProvider.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );

      Navigator.pop(context); // Close screen after success
    } catch (e) {
      debugPrint("CHANGE PASSWORD ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Old password is incorrect or failed to update"),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _passwordRequirementRow(bool condition, String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: condition ? Colors.green : Colors.grey,
          size: 10,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: condition ? Colors.green : Colors.grey,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: Container(color: Colors.grey, height: 0.5),
        ),
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
              "Change Password",
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Old Password"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "New Password"),
                ),
                const SizedBox(height: 4),
                _passwordRequirementRow(hasNumber, "At least 1 number"),
                _passwordRequirementRow(
                  hasUpperLower,
                  "Both uppercase and lowercase letters",
                ),
                _passwordRequirementRow(hasMinLength, "Minimum 8 characters"),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm New Password",
                  ),
                ),
                const SizedBox(height: 24),
                isLoading
                    ? const CircularProgressIndicator()
                    : AppButtons(
                        onPressed: () =>
                            _changePassword(context), // use a closure
                        text: "Change Password",
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
