import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/peereess.dart';

class PeereessProvider extends ChangeNotifier {
  /// LIST OF PICKUP STATIONS
  List<Peereess> peereessList = [];

  /// LOADING AND ERROR STATES
  bool isLoading = false;
  String? error;

  /// =============================
  /// CONTROLLERS FOR NEW PICKUP ROW
  /// =============================
  final TextEditingController pickupstationController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController regionController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  /// DISPOSE CONTROLLERS
  void disposeControllers() {
    pickupstationController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    feeController.dispose();
    regionController.dispose();
    cityController.dispose();
  }

  /// =============================
  /// FETCH ALL PICKUP STATIONS
  /// =============================
  Future<void> fetchPeereess() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.peereess,
      );

      peereessList =
          result.rows.map((row) => Peereess.fromMap(row.data)).toList();
    } catch (e) {
      debugPrint("FETCH PEEREESS ERROR: $e");
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// =============================
  /// FETCH PICKUP STATIONS BY REGION
  /// =============================
  Future<void> fetchByRegion(String region) async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.peereess,
        queries: [Query.equal('region', region)],
      );

      peereessList =
          result.rows.map((row) => Peereess.fromMap(row.data)).toList();
    } catch (e) {
      debugPrint("FETCH BY REGION ERROR: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// =============================
  /// CREATE NEW PICKUP STATION
  /// =============================
  Future<bool> createPeereess() async {
    if (pickupstationController.text.isEmpty ||
        phoneNumberController.text.isEmpty ||
        addressController.text.isEmpty ||
        feeController.text.isEmpty ||
        regionController.text.isEmpty ||
        cityController.text.isEmpty) {
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final data = {
        'pickupstation': pickupstationController.text.trim(),
        'phoneNumber': phoneNumberController.text.trim(),
        'address': addressController.text.trim(),
        'fee': int.tryParse(feeController.text.trim()) ?? 0,
        'region': regionController.text.trim(),
        'city': cityController.text.trim(),
      };

      final result = await AppwriteConfig.tablesDB.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.peereess,
        rowId: ID.unique(),
        data: data,
      );

      // Add newly created pickup station to the list
      peereessList.add(Peereess.fromMap(data));
      notifyListeners();

      // Clear controllers
      clearControllers();

      return true;
    } catch (e) {
      debugPrint("CREATE PEEREESS ERROR: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// =============================
  /// CLEAR INPUT CONTROLLERS
  /// =============================
  void clearControllers() {
    pickupstationController.clear();
    phoneNumberController.clear();
    addressController.clear();
    feeController.clear();
    regionController.clear();
    cityController.clear();
  }

  /// =============================
  /// CLEAR LIST
  /// =============================
  void clearList() {
    peereessList.clear();
    notifyListeners();
  }

  Future<void> saveMockDataToAppwrite(List<Peereess> data) async {
    isLoading = true;
    notifyListeners();

    try {
      for (var station in data) {
        await AppwriteConfig.tablesDB.createRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.peereess,
          rowId: ID.unique(),
          data: {
            'pickupstation': station.pickupstation,
            'phoneNumber': station.phoneNumber,
            'address': station.address,
            'fee': station.fee,
            'region': station.region,
            'city': station.city,
          },
        );
      }
      debugPrint("All mock data saved successfully!");
      await fetchPeereess(); // refresh local list
    } catch (e) {
      debugPrint("ERROR SAVING MOCK DATA: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
