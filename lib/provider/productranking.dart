import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:peereess/model/product.dart';

// ── Tunable weights ──────────────────────────────────
const double _likesWeight = 0.3;
const double _viewedBonus = 40.0;
const double _recencyWeight = 0.3;
const int _recencyDays = 30;
const double _jitterMax = 15.0;
const double _tierSize = 30.0;

/// Top-level function required by compute()
List<ProductModel> _rankIsolate(_RankPayload payload) {
  final random = Random();
  final now = DateTime.now();

  final scored = payload.products.map((p) {
    final isViewed = payload.viewedIds.contains(p.productId);

    final likesScore = log(p.likes + 1) * 20 * _likesWeight;
    final viewScore = isViewed ? _viewedBonus : 0.0;

    final ageInDays = now.difference(p.createdAt).inDays.abs();
    final recencyScore = (1.0 - (ageInDays / _recencyDays).clamp(0.0, 1.0)) *
        100 *
        _recencyWeight;

    final jitter = random.nextDouble() * _jitterMax;
    final total = likesScore + viewScore + recencyScore + jitter;

    return _ScoredProduct(product: p, score: total);
  }).toList();

  scored.sort((a, b) => b.score.compareTo(a.score));

  // Within-tier shuffle
  final result = <_ScoredProduct>[];
  int i = 0;
  while (i < scored.length) {
    final tierStart = scored[i].score;
    int j = i + 1;
    while (j < scored.length && (tierStart - scored[j].score) <= _tierSize) {
      j++;
    }
    final tier = scored.sublist(i, j)..shuffle(random);
    result.addAll(tier);
    i = j;
  }

  return result.map((s) => s.product).toList();
}

class ProductRanker {
  static final Random _random = Random();

  /// Async — runs ranking in a background isolate so the UI never blocks.
  static Future<List<ProductModel>> rankAsync(
    List<ProductModel> products,
    Set<String> viewedIds,
  ) async {
    if (products.isEmpty) return products;
    return compute(_rankIsolate, _RankPayload(products, viewedIds));
  }

  /// Sync fallback — only use for tiny lists (< 10 items) or tests.
  static List<ProductModel> rankSync(
    List<ProductModel> products,
    Set<String> viewedIds,
  ) {
    if (products.isEmpty) return products;
    return _rankIsolate(_RankPayload(products, viewedIds));
  }
}

// ── Payload passed to isolate ─────────────────────────
class _RankPayload {
  final List<ProductModel> products;
  final Set<String> viewedIds;
  const _RankPayload(this.products, this.viewedIds);
}

class _ScoredProduct {
  final ProductModel product;
  final double score;
  const _ScoredProduct({required this.product, required this.score});
}
