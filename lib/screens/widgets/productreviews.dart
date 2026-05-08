import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/model/product.dart';

/// ======================
/// REVIEW MODEL
/// ======================
class Review {
  final String username;
  final int stars;
  final DateTime date;
  final String message;

  Review({
    required this.username,
    required this.stars,
    required this.date,
    required this.message,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
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
/// CUSTOMER REVIEWS WIDGET
/// Uses ProductModel.reviews directly — no extra network fetch
/// ======================
class CustomerReviewsWidget extends StatelessWidget {
  final ProductModel product;

  const CustomerReviewsWidget({super.key, required this.product});

  /// Parse List<String> (JSON-encoded) → List<Review>
  List<Review> get _reviews {
    final raw = product.reviews ?? [];
    return raw
        .map((r) {
          try {
            final map = r is String
                ? Map<String, dynamic>.from(jsonDecode(r))
                : Map<String, dynamic>.from(r as Map);
            return Review.fromMap(map);
          } catch (_) {
            return Review(
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

  @override
  Widget build(BuildContext context) {
    final reviews = _reviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Customer Reviews (${reviews.length})",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        if (reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                "No reviews yet",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
          ),
      ],
    );
  }
}

/// ======================
/// REVIEW CARD
/// ======================
class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().format(review.date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < review.stars ? Icons.star : Icons.star_border,
                      color: const Color(0xffF4A300),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.message,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
