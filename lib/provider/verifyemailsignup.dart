import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';

class EmailVerificationService {
  static final Functions _functions = Functions(AppwriteConfig.client);

  static const functionId = "694af06c0019df7f3906";

  static Future<void> sendOtp(String email) async {
    final result = await _functions.createExecution(
      functionId: functionId,
      body: jsonEncode({
        "type": "emailVerification",
        "action": "sendOtp",
        "email": email,
      }),
    );

    final data = jsonDecode(result.responseBody ?? '{}');
    if (data["status"] != true) {
      throw Exception(data["message"] ?? "Failed to send OTP.");
    }
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final result = await _functions.createExecution(
      functionId: functionId,
      body: jsonEncode({
        "type": "emailVerification",
        "action": "verifyOtp",
        "email": email,
        "otp": otp,
      }),
    );

    final data = jsonDecode(result.responseBody ?? '{}');
    return data["status"] == true;
  }
}
