import 'package:flutter/material.dart';
import 'package:peereess/core/globalnavigation.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/screens/paymentresult.dart';

class Paymentloading extends StatefulWidget {
  final Future<void> Function() paymentFuture;

  const Paymentloading({super.key, required this.paymentFuture});

  @override
  State<Paymentloading> createState() => _PaymentloadingState();
}

class _PaymentloadingState extends State<Paymentloading> {
  @override
  void initState() {
    super.initState();
    _processPayment();
  }

  Future<void> _processPayment() async {
    try {
      await widget.paymentFuture();
    } catch (e) {
      debugPrint("Payment error: $e");
      // Navigate to failure page
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentResultPage(
            isSuccess: false,
            message: "Payment failed: $e",
          ),
        ),
      );
    }
  }

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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Payment Processing",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              20.getHeightWhiteSpacing,
              const CircularProgressIndicator(color: Color(0xffB0864C)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "Please wait while we process your payment",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ),
      ),
    );
  }
}
