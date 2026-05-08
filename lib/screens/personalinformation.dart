import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class Personalinformation extends StatefulWidget {
  const Personalinformation({super.key});

  @override
  State<Personalinformation> createState() => _PersonalinformationState();
}

class _PersonalinformationState extends State<Personalinformation> {
  bool isEditing = false;

  late TextEditingController fullNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();

    fullNameController = TextEditingController(
      text: authProvider.currentUserData?.fullName ?? '',
    );

    emailController = TextEditingController(
      text: authProvider.currentUserData?.email ?? '',
    );

    phoneController = TextEditingController(
      text: authProvider.currentUserData?.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Information Updated",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B4A1B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 52, color: Colors.brown.shade200),
            const SizedBox(height: 12),
            Text(
              "Your personal information has been updated successfully.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.brown.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xff9D6E2D))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: Container(color: Colors.grey, height: 0.5),
        ),
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
              "Personal Information",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                if (isEditing) {
                  authProvider.fullNameController.text =
                      fullNameController.text.trim();
                  authProvider.phoneNumberController.text =
                      phoneController.text.trim();

                  await authProvider.updateUserRow(
                    updateFullName: true,
                    updatePhoneNumber: true,
                  );

                  if (!context.mounted) return;

                  showSuccessDialog();
                }

                setState(() {
                  isEditing = !isEditing;
                });
              },
              child: Text(
                isEditing ? "Save" : "Edit",
                style: const TextStyle(fontSize: 13, color: Colors.red),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color.fromARGB(255, 233, 226, 226),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Full Name",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      isEditing
                          ? TextField(controller: fullNameController)
                          : Text(
                              authProvider.currentUserData?.fullName ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                      const Divider(),
                      const Text(
                        "Email",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      TextField(
                        controller: emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                      const Divider(),
                      const Text(
                        "Phone Number",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      isEditing
                          ? TextField(controller: phoneController)
                          : Text(
                              authProvider.currentUserData?.phoneNumber ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                    ],
                  ),
                ),
              ),
              30.getHeightWhiteSpacing,
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, "/deleteaccount"),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromARGB(255, 233, 226, 226),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text("Delete Account"),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
