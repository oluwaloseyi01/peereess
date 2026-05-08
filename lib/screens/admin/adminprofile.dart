import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';

import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';

import 'package:peereess/screens/changepassword.dart';

import 'package:peereess/screens/personalinformation.dart';

import 'package:provider/provider.dart';

class Adminprofile extends StatefulWidget {
  const Adminprofile({super.key});

  @override
  State<Adminprofile> createState() => _AdminprofileState();
}

class _AdminprofileState extends State<Adminprofile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      20.getWidthWhiteSpacing,
                      Text("Admin Profile", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  10.getHeightWhiteSpacing,
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 233, 226, 226),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  "Account Settings",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              5.getHeightWhiteSpacing,
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Personalinformation(),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline, size: 12),
                                    10.getWidthWhiteSpacing,
                                    Text(
                                      "Admin Information",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Spacer(),
                                    Icon(Icons.arrow_forward_ios, size: 10),
                                  ],
                                ),
                              ),
                              Divider(),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChangePasswordScreen(),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_outlined, size: 12),
                                    10.getWidthWhiteSpacing,
                                    Text(
                                      "Change Password",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Spacer(),
                                    Icon(Icons.arrow_forward_ios, size: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  10.getHeightWhiteSpacing,
                  5.getHeightWhiteSpacing,
                  5.getHeightWhiteSpacing,
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "ABOUT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  5.getHeightWhiteSpacing,
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 233, 226, 226),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Version",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Spacer(),
                                  Icon(Icons.arrow_forward_ios, size: 10),
                                ],
                              ),
                              Divider(),
                              Row(
                                children: [
                                  Text(
                                    "Legal-",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Spacer(),
                                  Icon(Icons.arrow_forward_ios, size: 10),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  20.getHeightWhiteSpacing,
                  AppButtons(
                    onPressed: () {
                      context.read<AuthProvider>().logOut(context);
                    },
                    text: "Logout",
                  ),
                  20.getHeightWhiteSpacing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
