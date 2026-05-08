import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/addaddress.dart';
import 'package:provider/provider.dart';

class Addressbook extends StatelessWidget {
  const Addressbook({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// BACK
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

                  16.getHeightWhiteSpacing,
                  const Text(
                    "Address Book",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  24.getHeightWhiteSpacing,

                  /// NO ADDRESS
                  if (!auth.hasAddress)
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            "No delivery address yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                          16.getHeightWhiteSpacing,
                          AppButtons(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddAddress(),
                                ),
                              );
                            },
                            text: "Add delivery Address",
                          ),
                        ],
                      ),
                    )

                  /// ADDRESS EXISTS
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color.fromARGB(255, 233, 226, 226),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.receiverFullName ?? "",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          4.getHeightWhiteSpacing,
                          Text(
                            auth.deliveryAddress ?? "",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            auth.state ?? "",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            auth.deliveryPhoneNumber ?? "",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          10.getHeightWhiteSpacing,
                          Row(
                            children: const [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Default Address",
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                          12.getHeightWhiteSpacing,
                          Row(
                            children: [
                              const Spacer(),

                              /// EDIT
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, "/addaddress");
                                },
                                child: const Icon(Icons.edit_outlined),
                              ),

                              12.getWidthWhiteSpacing,

                              /// DELETE
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text(
                                        "Delete Delivery Address",
                                      ),
                                      content: const Text(
                                        "Are you sure you want to delete this address?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            auth.deleteAddress();
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
