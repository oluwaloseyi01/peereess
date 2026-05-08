import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaystackWebProvider extends ChangeNotifier {
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  Future<void> startPaystackPaymentWeb({
    required BuildContext context,
    required double totalPrice,
    required Map userData,
    required String orderId,
    required Future<void> Function({
      required String paymentRef,
      required String paymentMethod,
    }) saveOrder,
  }) async {
    if (_isSaving) return;
    _setSaving(true);

    final email = userData["email"]?.toString() ?? "noemail@example.com";
    final amountInKobo = (totalPrice * 100).toInt();
    final reference = "PSK_${DateTime.now().millisecondsSinceEpoch}";
    const publicKey = "pk_live_4c6e2b2ff088cf1946c5886d5d2e7fda620e9c41";

    // ============================
    // STEP 1: REGISTER PAYMENT
    // ============================
    try {
      final regExecution = await AppwriteConfig.functions.createExecution(
        functionId: '695bf2d0002bbe7d0132',
        body: jsonEncode({
          "action": "registerPayment",
          "reference": reference,
          "expectedAmount": totalPrice,
        }),
        xasync: false,
      );

      final regBody = jsonDecode(regExecution.responseBody ?? '{}');
      if (regBody["status"] != true) {
        _setSaving(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                regBody["error"]?.toString() ?? "Failed to initialize payment.",
              ),
            ),
          );
        }
        return;
      }
    } catch (e) {
      _setSaving(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to initialize payment: $e")),
        );
      }
      return;
    }

    // ============================
    // STEP 2: BUILD PAYSTACK HTML
    // ============================
    final paystackHtml = """
<!DOCTYPE html>
<html>
<head><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body>
<script src="https://js.paystack.co/v1/inline.js"></script>
<script>
  window.onload = function() {
    const handler = PaystackPop.setup({
      key: '$publicKey',
      email: '$email',
      amount: $amountInKobo,
      currency: 'NGN',
      ref: '$reference',
      callback: function(response) {
        PaystackChannel.postMessage(JSON.stringify({
          type: 'paystack-success',
          reference: response.reference
        }));
      },
      onClose: function() {
        PaystackChannel.postMessage(JSON.stringify({
          type: 'paystack-cancelled'
        }));
      }
    });
    handler.openIframe();
  };
</script>
</body>
</html>
""";

    if (!context.mounted) {
      _setSaving(false);
      return;
    }

    // ============================
    // STEP 3: OPEN PAYSTACK FULL PAGE
    // ============================
    Map<String, dynamic>? paymentResult;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PaystackWebView(
          html: paystackHtml,
          onResult: (Map<String, dynamic> result) {
            paymentResult = result;
            Navigator.of(context).pop();
          },
          onDismissed: () {
            paymentResult ??= {"type": "paystack-cancelled"};
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    // ============================
    // STEP 4 + 5: VERIFY & NAVIGATE
    // Page is fully closed by this point — context is clean to use.
    // ============================

    if (!context.mounted) {
      _setSaving(false);
      return;
    }

    final result = paymentResult;

    if (result == null) {
      _setSaving(false);
      return;
    }

    final type = result["type"];

    if (type == "paystack-success") {
      final String paymentRef = result["reference"]?.toString() ?? "";

      try {
        final execution = await AppwriteConfig.functions.createExecution(
          functionId: '695bf2d0002bbe7d0132',
          body: jsonEncode({
            "action": "verify",
            "reference": paymentRef,
            "orderId": orderId,
          }),
          xasync: false,
        );

        final body = jsonDecode(execution.responseBody ?? '{}');
        final bool verified = body["verified"] == true;
        final String paymentRefFromBackend =
            body["reference"]?.toString() ?? paymentRef;

        if (verified) {
          await saveOrder(
            paymentRef: paymentRefFromBackend,
            paymentMethod: "Paystack",
          );
          if (context.mounted) {
            Navigator.pushReplacementNamed(
              context,
              "/paymentResultPage",
              arguments: {
                "isSuccess": true,
                "message":
                    "Payment successful. Reference: $paymentRefFromBackend",
                "reference": paymentRefFromBackend,
              },
            );
          }
        } else {
          final String reason =
              body["error"]?.toString() ?? "Verification failed.";
          if (context.mounted) {
            Navigator.pushReplacementNamed(
              context,
              "/paymentResultPage",
              arguments: {
                "isSuccess": false,
                "message": reason,
                "reference": paymentRefFromBackend,
              },
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(
            context,
            "/paymentResultPage",
            arguments: {
              "isSuccess": false,
              "message": "Verification error: $e",
              "reference": paymentRef,
            },
          );
        }
      } finally {
        _setSaving(false);
      }
    } else {
      // Cancelled
      _setSaving(false);
      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          "/paymentResultPage",
          arguments: {
            "isSuccess": false,
            "message": "Payment cancelled by user.",
            "reference": null,
          },
        );
      }
    }
  }
}

/// Full-page Paystack WebView screen
class _PaystackWebView extends StatefulWidget {
  final String html;
  final void Function(Map<String, dynamic> result) onResult;
  final VoidCallback onDismissed;

  const _PaystackWebView({
    required this.html,
    required this.onResult,
    required this.onDismissed,
  });

  @override
  State<_PaystackWebView> createState() => _PaystackWebViewState();
}

class _PaystackWebViewState extends State<_PaystackWebView> {
  late final WebViewController _controller;
  bool _resultHandled = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PaystackChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (_resultHandled) return;
          _resultHandled = true;

          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            widget.onResult(data);
          } catch (_) {
            widget.onDismissed();
          }
        },
      )
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          "Complete Payment",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Color(0xFF6B4A1B),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                if (!_resultHandled) {
                  _resultHandled = true;
                  widget.onDismissed();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.brown.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.brown.shade200,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.brown.shade400,
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
