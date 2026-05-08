import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:peereess/databases/config/apihelper.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/databases/config/error.dart';
import 'package:peereess/databases/config/errorhandling.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PIN HELPER — hashing only, user always enters raw 4-digit PIN
// ─────────────────────────────────────────────────────────────────────────────

class PinHelper {
  /// Hash a raw PIN before saving or comparing — never store raw PIN
  static String hash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Compare a raw entered PIN against a stored hash
  static bool verify(String enteredPin, String storedHash) {
    return hash(enteredPin) == storedHash;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WITHDRAW SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class WithdrawService extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> withdrawRows = [];

  // ── Shared call helper ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    // debugPrint('🔵 WithdrawService: ${body['action']}');
    try {
      final res = await ApiHelper.guard(
        () => AppwriteConfig.functions.createExecution(
          functionId: AppwriteConfig.productFunction,
          body: json.encode(body),
        ),
      );
      if (res == null) throw Exception('Session expired. Please log in again.');
      // debugPrint('🟢 WithdrawService response: ${res.responseBody}');
      return json.decode(res.responseBody) as Map<String, dynamic>;
    } catch (e, st) {
      // debugPrint('🔴 WithdrawService ERROR [${body['action']}]: $e\n$st');
      rethrow;
    }
  }

  // ── 1. Check if user has a PIN set ────────────────────────────────────────
  /// Returns true if the user's withdrawPin field is non-null and non-empty
  /// in the users collection.
  Future<bool> hasPin({required String userId}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _call({
        'action': 'getWithdrawPin',
        'userId': userId,
      });

      if (result['status'] == true) {
        final pin = result['data']['withdrawPin'] as String?;
        return pin != null && pin.isNotEmpty;
      }
      return false;
    } on SocketException {
      errorMessage = 'No internet connection';
      return false;
    } catch (e) {
      errorMessage = AppError.from(e).message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── 2. Create PIN — saves SHA-256 hash to users collection ───────────────
  /// Called on first-time PIN setup. Hashes the raw PIN before saving.
  Future<bool> createPin({
    required String userId,
    required String rowId,
    required String rawPin,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final hashedPin = PinHelper.hash(rawPin);

      final result = await _call({
        'action': 'saveWithdrawPin',
        'userId': userId,
        'rowId': rowId,
        'withdrawPin': hashedPin, // ✅ hash, never raw
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to save PIN.');
      }

      return true;
    } on SocketException {
      errorMessage = 'No internet connection';
      return false;
    } catch (e) {
      errorMessage = AppError.from(e).message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── 3. Verify PIN — checks entered PIN against stored hash ────────────────
  /// Fetches the stored hash from the users collection and compares locally.
  /// The raw PIN is never sent to the server for comparison.
  Future<bool> verifyPin({
    required String userId,
    required String enteredRawPin,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _call({
        'action': 'getWithdrawPin',
        'userId': userId,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Could not verify PIN.');
      }

      final storedHash = result['data']['withdrawPin'] as String?;
      if (storedHash == null || storedHash.isEmpty) {
        throw Exception('No PIN found. Please create a PIN first.');
      }

      // ✅ Compare locally — never send raw PIN to server
      return PinHelper.verify(enteredRawPin, storedHash);
    } on SocketException {
      errorMessage = 'No internet connection';
      return false;
    } catch (e) {
      errorMessage = AppError.from(e).message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── 4. Submit withdrawal — creates record in withdrawals collection ────────
  /// Creates a withdrawal entry with bankName, accountName, amount, status.
  /// Only call this after PIN is verified.
  Future<bool> submitWithdrawal({
    required String userId,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String amount,
    required double totalRevenue, // ✅ new parameter
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _call({
        'action': 'createWithdrawal',
        'userId': userId,
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'amount': amount,
        'totalRevenue': totalRevenue, // ✅ send to backend
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Withdrawal request failed.');
      }

      return true;
    } on SocketException {
      errorMessage = 'No internet connection';
      return false;
    } catch (e) {
      errorMessage = AppError.from(e).message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── 5. Fetch all withdrawals for a user ───────────────────────────────
  Future<void> fetchWithdrawalsForUser({required String userId}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _call({
        'action': 'getWithdrawals',
        'userId': userId,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to fetch withdrawals.');
      }

      final data = result['data'] as List<dynamic>? ?? [];

      withdrawRows = data.map((e) {
        if (e is Map<String, dynamic>) return e;
        return Map<String, dynamic>.from(e as Map);
      }).toList();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── ADD THIS METHOD to your WithdrawService ────────────────────
  // Paste this inside the WithdrawService class

  Future<bool> updateWithdrawalStatus({
    required String adminId,
    required String withdrawId,
    required String status,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _call({
        'action': 'updateWithdrawalStatus',
        'userId': adminId,
        'withdrawId': withdrawId,
        'status': status,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to update status.');
      }

      // Update locally so UI refreshes without refetch
      final idx = withdrawRows.indexWhere((w) => w['withdrawId'] == withdrawId);
      if (idx != -1) {
        withdrawRows[idx] = {...withdrawRows[idx], 'status': status};
        notifyListeners();
      }

      return true;
    } on SocketException {
      errorMessage = 'No internet connection';
      return false;
    } catch (e) {
      errorMessage = AppError.from(e).message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── 6. Fetch withdrawals enriched with user info ───────────────
  Future<void> fetchWithdrawalsWithUserInfo({required String userId}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // Step 1: Fetch all withdrawals
      final result = await _call({
        'action': 'getWithdrawals',
        'userId': userId,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to fetch withdrawals.');
      }

      final data = result['data'] as List<dynamic>? ?? [];

      final List<Map<String, dynamic>> rows = data.map((e) {
        if (e is Map<String, dynamic>) return e;
        return Map<String, dynamic>.from(e as Map);
      }).toList();

      // Step 2: For each withdrawal, fetch the user's name + phone
      final List<Map<String, dynamic>> enriched = [];

      for (final row in rows) {
        final String sellerId = (row['userId'] ?? '').toString();
        String fullName = '—';
        String phone = '—';

        if (sellerId.isNotEmpty) {
          try {
            // Reuse existing getWithdrawPin action which hits usersTableId
            // Better: call a user-fetch action — here we query users table directly
            final userResult = await _call({
              'action': 'getUserInfo',
              'userId': sellerId,
            });

            if (userResult['status'] == true) {
              fullName = userResult['data']['fullName']?.toString() ?? '—';
              phone = userResult['data']['phoneNumber']?.toString() ?? '—';
            }
          } catch (_) {
            // Non-fatal — keep defaults
          }
        }

        enriched.add({...row, 'sellerName': fullName, 'sellerPhone': phone});
      }

      withdrawRows = enriched;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  // ── Error helpers ──────────────────────────────────────────────────────────

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
