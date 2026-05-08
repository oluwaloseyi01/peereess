import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/widgets/location.widget.dart';
import 'package:provider/provider.dart';

class AddAddress extends StatefulWidget {
  const AddAddress({super.key});

  @override
  State<AddAddress> createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

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
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back,
                                size: 18,
                                color: Color(0xff9D6E2D),
                              ),
                            ),
                          ),
                        ),
                        20.getWidthWhiteSpacing,
                        const Text(
                          "Add Address",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    20.getHeightWhiteSpacing,

                    // Address Fields
                    const LocationWidget(),
                  ],
                ),
              ),
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
              text: "Save",
              onPressed: () async {
                FocusScope.of(context).unfocus(); // hide keyboard

                // Validate form
                if (!_formKey.currentState!.validate()) return;

                try {
                  // Save address using provider
                  await auth.updateUserRow(
                    updateReceiverName: true,
                    updatePhoneCode: true,
                    updateDeliveryPhoneNumber: true,
                    updateState: true,
                    updateDeliveryAddress: true,
                  );

                  if (!context.mounted) return;

                  // Return updated address & phone to previous page
                  Navigator.pop(context, {
                    'address': auth.deliveryAddressController.text.trim(),
                    'phone': auth.deliveryPhoneNumberController.text.trim(),
                  });

                  // Optional: show success dialog
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text(
                        "Address Saved",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B4A1B)),
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
                          const Text(
                            "Your delivery address has been saved successfully.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  // Show simple error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to save address: $e")),
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
