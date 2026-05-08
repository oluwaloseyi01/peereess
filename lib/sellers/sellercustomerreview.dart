import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:appwrite/appwrite.dart';

/// ======================
/// REVIEW MODEL
/// ======================
class Review {
  final String username;
  final int stars;
  final DateTime date;
  final String message;
  final String productTitle;

  Review({
    required this.username,
    required this.stars,
    required this.date,
    required this.message,
    required this.productTitle,
  });

  factory Review.fromMap(Map<String, dynamic> map, String productTitle) {
    DateTime parsedDate;

    try {
      parsedDate = DateTime.parse(map['date'] ?? "");
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return Review(
      username: map['username'] ?? "Anonymous",
      stars:
          map['stars'] != null ? int.tryParse(map['stars'].toString()) ?? 0 : 0,
      date: parsedDate,
      message: map['message'] ?? "",
      productTitle: productTitle,
    );
  }
}

/// ======================
/// SELLER CUSTOMER REVIEWS
/// ======================
class SellerCustomerReviewWidget extends StatefulWidget {
  const SellerCustomerReviewWidget({super.key});

  @override
  State<SellerCustomerReviewWidget> createState() =>
      _SellerCustomerReviewWidgetState();
}

class _SellerCustomerReviewWidgetState
    extends State<SellerCustomerReviewWidget> {
  bool _loading = true;
  List<Review> reviews = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReviews();
    });
  }

  Future<void> _fetchReviews() async {
    final sellerId = context.read<AuthProvider>().userId;

    if (sellerId == null || sellerId.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final products = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        // ✅ CORRECT
        queries: [Query.equal('userId', sellerId)],
      );

      final List<Review> allReviews = [];

      for (final row in products.rows) {
        final data = Map<String, dynamic>.from(row.data);

        final rawReviews = data['reviews'];

        if (rawReviews is List) {
          for (final r in rawReviews) {
            Map<String, dynamic>? reviewMap;

            if (r is String) {
              try {
                reviewMap = jsonDecode(r);
              } catch (_) {}
            } else if (r is Map) {
              reviewMap = Map<String, dynamic>.from(r);
            }

            if (reviewMap != null) {
              allReviews.add(Review.fromMap(reviewMap, data['title'] ?? ""));
            }
          }
        }
      }

      allReviews.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          reviews = allReviews;
        });
      }
    } catch (e) {
      debugPrint("Error fetching seller reviews: $e");

      if (mounted) {
        setState(() {
          reviews = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isConnected) {
      return const SizedBox();
    }

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
      );
    }

    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text("No reviews yet", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        return _buildReviewCard(reviews[index]);
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    final formattedDate = DateFormat.yMMMd().format(review.date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// username + stars + date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
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

          const SizedBox(height: 6),

          Text(
            review.productTitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 4),

          Text(review.message, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
