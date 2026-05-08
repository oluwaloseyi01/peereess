import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';

/// ======================
/// REVIEW MODEL
/// ======================
class ReviewModel {
  final String username;
  final int stars;
  final DateTime date;
  final String message;

  ReviewModel({
    required this.username,
    required this.stars,
    required this.date,
    required this.message,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      username: map['username'] ?? "",
      stars:
          map['stars'] != null ? int.tryParse(map['stars'].toString()) ?? 0 : 0,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      message: map['message'] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "username": username,
      "stars": stars,
      "date": date.toIso8601String(),
      "message": message,
    };
  }
}

/// ======================
/// REVIEW PAGE
/// ======================
class ReviewPage extends StatefulWidget {
  final ProductModel product; // ✅ full product — no extra fetch needed

  const ReviewPage({super.key, required this.product});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late List<ReviewModel> _reviews;
  bool _isSubmitting = false;
  int _selectedStars = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ✅ Parse reviews from ProductModel — zero network calls on load
    _reviews = _parseReviews(widget.product.reviews ?? []);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  /// Parse List<String> (JSON-encoded) → List<ReviewModel>
  List<ReviewModel> _parseReviews(List<String> raw) {
    return raw
        .map((r) {
          try {
            final map = Map<String, dynamic>.from(jsonDecode(r));
            return ReviewModel.fromMap(map);
          } catch (_) {
            return ReviewModel(
              username: '',
              stars: 0,
              message: '',
              date: DateTime.now(),
            );
          }
        })
        .where((r) => r.username.isNotEmpty)
        .toList();
  }

  /// Check if current user has already reviewed
  bool get _hasReviewed {
    final username =
        context.read<AuthProvider>().currentUserData?.fullName ?? "";
    if (username.isEmpty) return false;
    return _reviews.any((r) => r.username == username);
  }

  /// ======================
  /// SUBMIT REVIEW — only network call here
  /// ======================
  Future<void> _submitReview() async {
    if (_selectedStars == 0 || _reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select stars and write a review")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final String userId = authProvider.currentUserData?.userId ?? "";
      final String username =
          authProvider.currentUserData?.fullName ?? "Anonymous";

      final execution = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({
          "action": "addReview",
          "userId": userId,
          "productId": widget.product.productId,
          "stars": _selectedStars,
          "message": _reviewController.text.trim(),
        }),
      );

      final response = jsonDecode(execution.responseBody);

      if (response["status"] == true) {
        // ✅ Optimistically append new review to local list — no re-fetch needed
        final newReview = ReviewModel(
          username: username,
          stars: _selectedStars,
          message: _reviewController.text.trim(),
          date: DateTime.now(),
        );

        setState(() {
          _reviews = [newReview, ..._reviews];
          _reviewController.clear();
          _selectedStars = 0;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response["message"] ?? "Failed to submit")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit review")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// ======================
  /// UI
  /// ======================
  @override
  Widget build(BuildContext context) {
    final hasReviewed = _hasReviewed;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: Container(color: Colors.grey, height: 0.5),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: Color(0xff9D6E2D),
                ),
              ),
            ),
            10.getWidthWhiteSpacing,
            Expanded(
              child: Text(
                "Reviews • ${widget.product.title}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ✅ Show form only if user hasn't reviewed yet
              if (!hasReviewed) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Write a Review",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: () =>
                          setState(() => _selectedStars = index + 1),
                      icon: Icon(
                        index < _selectedStars ? Icons.star : Icons.star_border,
                        color: const Color(0xffF4A300),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Share your thoughts on this product...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _isSubmitting
                      ? const Center(child: LogoLoadingIndicator())
                      : AppButtons(
                          onPressed: _submitReview,
                          text: "Submit Review",
                        ),
                ),
                const SizedBox(height: 24),
              ],

              /// REVIEWS LIST
            ],
          ),
        ),
      ),
    );
  }
}

/// ======================
/// REVIEW CARD
/// ======================
