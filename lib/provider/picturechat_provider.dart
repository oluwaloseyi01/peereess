import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/product.dart';
import 'package:uuid/uuid.dart';

class PictureSearchProvider extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  List<ProductModel> _searchResults = [];

  File? get selectedImage => _selectedImage;
  bool get hasImage => _selectedImage != null;
  List<ProductModel> get searchResults => _searchResults;

  /// ============================
  /// PICK IMAGE FROM CAMERA/GALLERY
  /// ============================
  Future<void> pickImage({required bool fromCamera}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("PictureSearchProvider — pickImage error: $e");
    }
  }

  /// ============================
  /// UPLOAD IMAGE TO APPWRITE STORAGE
  /// ============================
  Future<String?> _uploadImageToAppwrite(File file) async {
    try {
      final fileId = const Uuid().v4();

      final uploaded = await AppwriteConfig.storage.createFile(
        bucketId: AppwriteConfig.bucketId,
        fileId: fileId,
        file: InputFile.fromPath(path: file.path),
      );

      return uploaded.$id; // this *is* correct — uploaded file ID
    } catch (e) {
      debugPrint("PictureSearchProvider — upload error: $e");
      return null;
    }
  }

  /// ============================
  /// SEARCH WITH IMAGE — CALL FUNCTION
  /// ============================
  Future<void> searchWithImage() async {
    if (_selectedImage == null) return;

    try {
      // Upload file
      final fileId = await _uploadImageToAppwrite(_selectedImage!);
      if (fileId == null) return;

      // Execute function synchronously
      final execution = await AppwriteConfig.functions.createExecution(
        functionId: 'pictureSearchFunction', // <-- replace with your real ID
        body: jsonEncode({"fileId": fileId}), // any JSON your function expects
        xasync: false, // make it wait for completion
      );

      // Read the **responseBody** from the execution
      final raw = execution.responseBody;
      debugPrint("function responseBody → $raw");

      // If body contains JSON array of products
      if (raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _searchResults = decoded
            .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _searchResults = [];
      }
    } catch (e) {
      debugPrint("PictureSearchProvider — function call failed: $e");
      _searchResults = [];
    }

    notifyListeners();
  }

  /// ============================
  /// CLEAR SEARCH
  /// ============================
  void clearSearch() {
    _selectedImage = null;
    _searchResults = [];
    notifyListeners();
  }
}
