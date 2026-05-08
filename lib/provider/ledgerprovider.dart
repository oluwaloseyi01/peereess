import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:peereess/databases/config/appwrite.dart';

class LedgerProvider extends ChangeNotifier {
  bool isLoading = false;

  double balance = 0;

  double totalCredits = 0; // total earnings
  double totalDebits = 0; // total withdrawals

  List<Map<String, dynamic>> ledgerRows = [];

  Future<void> fetchLedger({required String userId}) async {
    if (userId.isEmpty) return;

    isLoading = true;
    notifyListeners();

    try {
      double credits = 0;
      double debits = 0;

      final List<Map<String, dynamic>> allRows = [];

      const int pageSize = 100;
      int offset = 0;

      while (true) {
        final response = await AppwriteConfig.tablesDB.listRows(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.ledger,
          queries: [
            Query.equal('userId', userId),
            Query.limit(pageSize),
            Query.offset(offset),
          ],
        );

        for (final row in response.rows) {
          final data = Map<String, dynamic>.from(row.data);

          allRows.add(data);

          final type = (data['type'] ?? '').toString().toLowerCase().trim();

          final amount = (data['amount'] as num? ?? 0).toDouble();

          if (type == 'credit') {
            credits += amount;
          } else if (type == 'debit') {
            debits += amount;
          }
        }

        if (response.rows.length < pageSize) break;

        offset += pageSize;
      }

      ledgerRows = allRows;

      totalCredits = credits;
      totalDebits = debits;

      balance = credits - debits;
    } catch (e) {
      // debugPrint('LedgerProvider fetchLedger error: $e');

      balance = 0;
      totalCredits = 0;
      totalDebits = 0;

      ledgerRows = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  double getBalance(String userId) {
    return balance;
  }
}
