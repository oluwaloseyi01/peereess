import 'dart:convert';
import 'package:appwrite/appwrite.dart';

class ResetPasswordService {
  late final Client _client;
  late final Functions _functions;

  // CHANGE THIS TO YOUR FUNCTION ID
  static const String _functionId = '694af06c0019df7f3906';

  ResetPasswordService() {
    _client = Client()
      ..setEndpoint('https://nyc.cloud.appwrite.io/v1')
      ..setProject('69383047001867cb050b');

    _functions = Functions(_client);
  }

  /// =========================
  /// SEND RESET OTP
  /// =========================
  Future<Map<String, dynamic>> sendResetOtp({required String email}) async {
    try {
      final exec = await _functions.createExecution(
        functionId: _functionId,
        body: jsonEncode({
          "type": "passwordReset", // ← must include type
          "action": "sendOtp",
          "email": email,
        }),
      );

      if (exec.responseBody == null || exec.responseBody!.isEmpty) {
        return {"status": false, "message": "Empty response from server"};
      }

      return jsonDecode(exec.responseBody!);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  /// =========================
  /// VERIFY OTP
  /// =========================
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final exec = await _functions.createExecution(
        functionId: _functionId,
        body: jsonEncode({
          "type": "passwordReset", // ← must include type
          "action": "verifyOtp",
          "email": email,
          "otp": otp,
        }),
      );

      if (exec.responseBody == null || exec.responseBody!.isEmpty) {
        return {"status": false, "message": "Empty response from server"};
      }

      return jsonDecode(exec.responseBody!);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  /// =========================
  /// RESET PASSWORD
  /// =========================
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final exec = await _functions.createExecution(
        functionId: _functionId,
        body: jsonEncode({
          "type": "passwordReset", // ← must include type
          "action": "resetPassword",
          "email": email,
          "otp": otp,
          "new_password": newPassword, // match your function field
        }),
      );

      if (exec.responseBody == null || exec.responseBody!.isEmpty) {
        return {"status": false, "message": "Empty response from server"};
      }

      return jsonDecode(exec.responseBody!);
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }
}
