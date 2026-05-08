import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/product.dart';

import 'package:peereess/provider/cloudinaryservice.dart'; // ✅ ADD THIS

/// =======================
/// VARIANT FORM
/// =======================
class VariantForm {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  void dispose() {
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
  }
}

/// =======================
/// PRODUCT UPLOAD PROVIDER
/// =======================
class ProductUploadProvider extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  TextEditingController refundableController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController colorsController = TextEditingController();
  final TextEditingController shippedFromController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();
  final TextEditingController deliveryDaysController = TextEditingController();

  final List<VariantForm> variants = [];

  List<File> selectedImages = [];
  List<String> uploadedImageUrls = [];

  bool isLoading = false;
  List<Map<String, dynamic>> sellerProducts = [];
  int productCount = 0;
  bool isLoadingProducts = false;
  List<Uint8List> webImages = [];

  int get pendingProductsCount =>
      sellerProducts.where((p) => p['status'] == 'pending').length;

  // ===================== VARIANT HELPERS =====================
  void addVariant() {
    variants.add(VariantForm());
    notifyListeners();
  }

  void removeVariant(int index) {
    variants[index].dispose();
    variants.removeAt(index);
    notifyListeners();
  }

  // ===================== IMAGE PICKING =====================
  Future<void> pickImages() async {
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

    // Combine old + new, max 6 images
    webImages = [...webImages, ...newImages].take(6).toList();

    notifyListeners();
  }

  // ===================== UPLOAD IMAGES TO CLOUDINARY =====================
  Future<List<String>> uploadImages() async {
    // ✅ Upload each image bytes to Cloudinary and collect URLs
    final List<String> urls = await CloudinaryService.uploadImageBytes(
      webImages,
    );
    uploadedImageUrls = urls;
    return urls;
  }

  // ===================== SERVER FUNCTION CALL =====================
  Future<Map<String, dynamic>> _callFunction(Map<String, dynamic> body) async {
    final res = await AppwriteConfig.functions.createExecution(
      functionId: AppwriteConfig.productFunction,
      body: json.encode(body),
    );
    return json.decode(res.responseBody) as Map<String, dynamic>;
  }

  // ===================== CREATE PRODUCT =====================
  Future<void> createProduct(BuildContext context, String? userId) async {
    if (userId == null || userId.isEmpty) {
      _toast(context, "Please login again");
      return;
    }
    if (webImages.isEmpty) {
      _toast(context, "Please select product images");
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
      // 1️⃣ Upload images to Cloudinary
      final imageUrls = await uploadImages();

      // 2️⃣ Prepare data
      final colors = colorsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // 3️⃣ Build variants with stock field
      final variantList = variants.map((v) {
        final cleanPrice = v.priceController.text.trim().replaceAll(',', '');
        final cleanStock = v.stockController.text.trim().replaceAll(',', '');

        return jsonEncode({
          "description": v.descriptionController.text.trim(),
          "price": double.tryParse(cleanPrice) ?? 0,
          "stock": int.tryParse(cleanStock) ?? 0,
        });
      }).toList();

      // 4️⃣ Send to server function
      final result = await _callFunction({
        'action': 'createProduct',
        'userId': userId,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': categoryController.text.trim(),
        'refundable': refundableController.text.trim(),
        'shippedFrom': shippedFromController.text.trim(),
        'discount': int.tryParse(discountController.text.trim()) ?? 0,
        'deliveryDays': int.tryParse(deliveryDaysController.text.trim()) ?? 0,
        'imageUrl': imageUrls,
        'colors': colors,
        'variants': variantList,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to create product.');
      }

      _toast(context, "Product uploaded successfully!");
      _reset();
    } catch (e) {
      // debugPrint("UPLOAD ERROR: $e");
      _toast(context, "Failed to upload product: ${e.toString()}");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================== DELETE PRODUCT =====================
  Future<void> deleteProduct(String productId, String userId) async {
    try {
      final result = await _callFunction({
        'action': 'deleteProduct',
        'userId': userId,
        'productId': productId,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to delete product.');
      }

      sellerProducts.removeWhere((p) => p['productId'] == productId);
      notifyListeners();
    } catch (e) {
      // debugPrint("Error deleting product: $e");
      rethrow;
    }
  }

  // ===================== APPROVE PRODUCT (ADMIN) =====================
  Future<void> approveProduct(String productId, String requesterId) async {
    try {
      final result = await _callFunction({
        'action': 'approveProduct',
        'requesterId': requesterId,
        'productId': productId,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to approve product.');
      }

      sellerProducts.removeWhere((p) => p["rowId"] == productId);
      notifyListeners();
    } catch (e) {
      // debugPrint("APPROVE PRODUCT ERROR: $e");
      rethrow;
    }
  }

  // ===================== UPDATE PRODUCT =====================
  Future<void> updateProductPartial({
    required String productId,
    required String userId,
    required Map<String, dynamic> updatedFields,
  }) async {
    try {
      final index = sellerProducts.indexWhere(
        (p) => p['productId'] == productId,
      );
      if (index != -1) {
        sellerProducts[index] = {...sellerProducts[index], ...updatedFields};
        notifyListeners();
      }

      final result = await _callFunction({
        'action': 'updateProduct',
        'userId': userId,
        'productId': productId,
        ...updatedFields,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to update product.');
      }
    } catch (e) {
      // debugPrint("Update product error: $e");
      rethrow;
    }
  }

  // ===================== READ-ONLY FETCHES =====================
  Future<void> fetchSellerProducts(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    try {
      isLoadingProducts = true;
      notifyListeners();

      final result = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        queries: [
          Query.equal("userId", userId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      sellerProducts =
          result.rows.map((row) => row.data..["rowId"] = row.$id).toList();
      productCount = result.total;
      notifyListeners();
    } catch (e) {
      // debugPrint("FETCH SELLER PRODUCTS ERROR: $e");
    } finally {
      isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllProducts() async {
    isLoadingProducts = true;
    notifyListeners();
    try {
      final response = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
      );
      sellerProducts =
          response.rows.map((row) => row.data as Map<String, dynamic>).toList();
    } catch (e) {
      // debugPrint("FETCH ALL PRODUCTS ERROR: $e");
    } finally {
      isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingProductsForAdmin() async {
    isLoadingProducts = true;
    notifyListeners();
    try {
      final result = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        queries: [
          Query.notEqual("status", "approved"),
          Query.orderDesc('\$createdAt'),
        ],
      );
      sellerProducts =
          result.rows.map((row) => row.data..["rowId"] = row.$id).toList();
      productCount = result.total;
    } catch (e) {
      // debugPrint("FETCH ADMIN PENDING PRODUCTS ERROR: $e");
    } finally {
      isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingProductForAdmin() => fetchPendingProductsForAdmin();

  // ===================== HELPERS =====================
  void _reset() {
    titleController.clear();
    descriptionController.clear();
    quantityController.clear();
    discountController.clear();
    categoryController.clear();
    colorsController.clear();
    shippedFromController.clear();
    ratingController.clear();
    deliveryDaysController.clear();
    refundableController.clear();
    for (final v in variants) v.dispose();
    variants.clear();
    selectedImages.clear();
    uploadedImageUrls.clear();
    webImages.clear();
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

final dummyProduct = ProductModel(
  productId: '',
  title: '',
  description: '',
  imageUrl: [],
  quantity: 0,
  sellerName: '',
  discount: 0,
  likes: 0,
  category: '',
  createdAt: DateTime.now(),
  likedBy: [],
  variants: [],
);
