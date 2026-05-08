import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';

class DeleteAccountService {
  final Functions functions = Functions(AppwriteConfig.client);

  /// Call Appwrite function to delete a user account
  Future<void> deleteUser({
    required String userId,
    required String rowId,
  }) async {
    try {
      // Use 'body' instead of 'data'
      final execution = await functions.createExecution(
        functionId: "69511660003cc5877431", // your Appwrite function ID
        body: jsonEncode({'userId': userId, 'rowId': rowId}),
      );

      // Optional: log execution ID
      print("Delete user function executed: ${execution.$id}");
    } catch (e) {
      print("DELETE ACCOUNT FUNCTION ERROR: $e");
      rethrow;
    }
  }
}
