import 'package:flutter/material.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/deliveryfeemodel.dart';

class DeliveryFeeProvider extends ChangeNotifier {
  DeliveryFeeModel? _deliveryFee;
  bool _isLoading = false;

  DeliveryFeeModel? get deliveryFee => _deliveryFee;

  bool get isLoading => _isLoading;

  double get generalDeliveryFee => _deliveryFee?.generalDeliveryFee ?? 0;

  Future<void> fetchDeliveryFee() async {
    try {
      _isLoading = true;
      notifyListeners();

      final rows = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.deliveryfee, // make sure tableId is correct
      );

      if (rows.total > 0) {
        _deliveryFee = DeliveryFeeModel.fromMap(rows.rows.first.data);
      } else {
        debugPrint("No delivery fee row found in DB.");
      }
    } catch (e) {
      debugPrint("FETCH DELIVERY FEE ERROR: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
