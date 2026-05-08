import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/screens/widgets/peereesslocation.dart';
import 'package:peereess/model/peereess.dart';

class Pickup extends StatefulWidget {
  const Pickup({super.key});

  @override
  State<Pickup> createState() => _PickupState();
}

class _PickupState extends State<Pickup> {
  Peereess? selectedPickup;

  void _onConfirm() {
    if (selectedPickup != null) {
      Navigator.pop(context, selectedPickup);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a pickup station")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
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
          child: Column(
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
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
                      "Select Pick Up",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              10.getHeightWhiteSpacing,

              /// DRAG INDICATOR
              Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              10.getHeightWhiteSpacing,

              /// PICKUP LIST
              Expanded(
                child: Peereesslocation(
                  onPickupSelected: (Peereess pickup) {
                    setState(() {
                      selectedPickup = pickup;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      /// CONFIRM BUTTON
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: AppButtons(onPressed: _onConfirm, text: "Confirm"),
        ),
      ),
    );
  }
}
