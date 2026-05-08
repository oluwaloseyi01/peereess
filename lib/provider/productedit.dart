import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/provider/cloudinaryservice.dart';
import 'package:peereess/provider/productupload_provider.dart';

/// =======================
/// PRODUCT EDIT PROVIDER (extends ProductUploadProvider)
/// =======================
class ProductEditProvider extends ProductUploadProvider {
  String productId = '';
  Map<String, dynamic> productData = {};

  bool isInitializing = true;
  List<String> existingImageUrls = [];
  List<String> imagesToDelete = [];

  // Constructor with optional parameters
  ProductEditProvider({String? productId, Map<String, dynamic>? productData}) {
    if (productId != null && productData != null) {
      this.productId = productId;
      this.productData = productData;
      _initializeFromProductData();
    } else {
      // If no data provided, set isInitializing to false
      // User must call initialize() manually
      isInitializing = false;
    }
  }

  // Manual initialization method for when using global ChangeNotifierProvider
  void initialize(String id, Map<String, dynamic> data) {
    productId = id;
    productData = data;
    isInitializing = true;
    _initializeFromProductData();
  }

  void _initializeFromProductData() {
    // Populate text fields from productData
    titleController.text = productData['title'] ?? '';
    descriptionController.text = productData['description'] ?? '';
    discountController.text = productData['discount']?.toString() ?? '';
    categoryController.text = productData['category'] ?? '';
    refundableController.text = productData['refundable'] ?? '';
    shippedFromController.text = productData['shippedFrom'] ?? '';
    deliveryDaysController.text = productData['deliveryDays']?.toString() ?? '';

    // Handle colors (could be List or String)
    if (productData['colors'] != null) {
      if (productData['colors'] is List) {
        colorsController.text = (productData['colors'] as List).join(', ');
      } else {
        colorsController.text = productData['colors'].toString();
      }
    }

    // Load existing images
    if (productData['imageUrl'] != null) {
      if (productData['imageUrl'] is List) {
        existingImageUrls = List<String>.from(productData['imageUrl']);
      }
    }

    // Load existing variants
    if (productData['variants'] != null && productData['variants'] is List) {
      for (var variantData in productData['variants']) {
        // Parse the JSON string if needed
        final Map<String, dynamic> variant = variantData is String
            ? json.decode(variantData)
            : variantData as Map<String, dynamic>;

        final variantForm = VariantForm();
        variantForm.descriptionController.text = variant['description'] ?? '';
        variantForm.priceController.text = variant['price']?.toString() ?? '';
        variantForm.stockController.text = variant['stock']?.toString() ?? '';
        variants.add(variantForm);
      }
    }

    // If no variants exist, add one empty variant
    if (variants.isEmpty) {
      addVariant();
    }

    isInitializing = false;
    notifyListeners();
  }

  bool get hasImages => existingImageUrls.isNotEmpty || webImages.isNotEmpty;
  int get totalImageCount => existingImageUrls.length + webImages.length;

  void removeExistingImage(int index) {
    if (index < existingImageUrls.length) {
      imagesToDelete.add(existingImageUrls[index]);
      existingImageUrls.removeAt(index);
      notifyListeners();
    }
  }

  void removeNewImage(int index) {
    if (index < webImages.length) {
      webImages.removeAt(index);
      notifyListeners();
    }
  }

  // Override pickImages to respect the 6 image limit with existing images
  @override
  Future<void> pickImages() async {
    if (totalImageCount >= 6) {
      return; // Max 6 images
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    final newImages = result.files
        .where((f) => f.bytes != null)
        .map((f) => f.bytes!)
        .toList();

    // Calculate remaining slots
    int remainingSlots = 6 - totalImageCount;
    webImages = [...webImages, ...newImages].take(remainingSlots).toList();

    notifyListeners();
  }

  // Upload only NEW images
  Future<List<String>> uploadNewImages() async {
    return await CloudinaryService.uploadImageBytes(webImages);
  }

  // Update product method
  Future<void> updateProduct(BuildContext context, String? userId) async {
    if (userId == null || userId.isEmpty) {
      _toast(context, "Please login again");
      return;
    }

    if (!hasImages) {
      _toast(context, "Please add at least one image");
      return;
    }

    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        categoryController.text.isEmpty) {
      _toast(context, "Please fill all required fields");
      return;
    }

    if (refundableController.text.isEmpty) {
      _toast(context, "Please select if the product is refundable");
      return;
    }

    if (variants.isEmpty) {
      _toast(context, "Please add at least one variant");
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // 1️⃣ Upload new images if any
      List<String> newImageUrls = [];
      if (webImages.isNotEmpty) {
        newImageUrls = await uploadNewImages();
      }

      // 2️⃣ Combine existing + new image URLs
      final allImageUrls = [...existingImageUrls, ...newImageUrls];

      // 3️⃣ Prepare colors
      final colors = colorsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // 4️⃣ Build variants
      final variantList = variants.map((v) {
        final cleanPrice = v.priceController.text.trim().replaceAll(',', '');
        final cleanStock = v.stockController.text.trim().replaceAll(',', '');

        return jsonEncode({
          "description": v.descriptionController.text.trim(),
          "price": double.tryParse(cleanPrice) ?? 0,
          "stock": int.tryParse(cleanStock) ?? 0,
        });
      }).toList();

      // 5️⃣ Call update function
      final result = await _callFunction({
        'action': 'updateProduct',
        'userId': userId,
        'productId': productId,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': categoryController.text.trim(),
        'refundable': refundableController.text.trim(),
        'shippedFrom': shippedFromController.text.trim(),
        'discount': int.tryParse(discountController.text.trim()) ?? 0,
        'deliveryDays': int.tryParse(deliveryDaysController.text.trim()) ?? 0,
        'imageUrl': allImageUrls,
        'colors': colors,
        'variants': variantList,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to update product.');
      }

      _toast(context, "Product updated successfully!");

      // ✅ Clear and reset everything after successful update
      reset();

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      // debugPrint("UPDATE ERROR: $e");
      _toast(context, "Failed to update product: ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Helper to call server function
  Future<Map<String, dynamic>> _callFunction(Map<String, dynamic> body) async {
    final res = await AppwriteConfig.functions.createExecution(
      functionId: AppwriteConfig.productFunction,
      body: json.encode(body),
    );
    return json.decode(res.responseBody) as Map<String, dynamic>;
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Reset method to clear all state (call when leaving edit screen)
  void reset() {
    productId = '';
    productData = {};
    existingImageUrls.clear();
    imagesToDelete.clear();
    webImages.clear();
    isInitializing = false;

    // Clear inherited fields from ProductUploadProvider
    titleController.clear();
    descriptionController.clear();
    discountController.clear();
    categoryController.clear();
    refundableController.clear();
    shippedFromController.clear();
    deliveryDaysController.clear();
    colorsController.clear();

    for (var variant in variants) {
      variant.dispose();
    }
    variants.clear();

    notifyListeners();
  }
}
