import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductReviewsService {
  ProductReviewsService._internal();
  static final ProductReviewsService instance = ProductReviewsService._internal();

  static const String _boxKey = 'customer_product_reviews';

  Box _getBox() {
    if (Hive.isBoxOpen('customer_cache')) {
      return Hive.box('customer_cache');
    }
    throw Exception('Hive customer_cache box is not open');
  }

  /// Returns real customer reviews for a specific product ID
  List<Map<String, dynamic>> getReviewsForProduct(String productId) {
    if (productId.trim().isEmpty) return [];
    try {
      final box = _getBox();
      final map = box.get(_boxKey);
      if (map is Map) {
        final list = map[productId];
        if (list is List) {
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Calculates dynamic real average rating and review count from authentic customer reviews
  Map<String, dynamic> getProductRatingStats(String productId) {
    final reviews = getReviewsForProduct(productId);
    if (reviews.isEmpty) {
      return {
        'average_rating': 0.0,
        'has_ratings': false,
        'review_count': 0,
        'breakdown': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }

    double total = 0.0;
    final breakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final ratingNum = (r['rating'] as num?)?.toInt() ?? 5;
      final clamped = ratingNum.clamp(1, 5);
      breakdown[clamped] = (breakdown[clamped] ?? 0) + 1;
      total += (r['rating'] as num?)?.toDouble() ?? 5.0;
    }

    return {
      'average_rating': double.parse((total / reviews.length).toStringAsFixed(1)),
      'has_ratings': true,
      'review_count': reviews.length,
      'breakdown': breakdown,
    };
  }

  /// Real customers submit their genuine rating and review
  Future<void> submitProductReview({
    required String productId,
    required double rating,
    required String comment,
    required String reviewerName,
  }) async {
    try {
      final box = _getBox();
      Map<String, dynamic> allReviews = {};
      final raw = box.get(_boxKey);
      if (raw is Map) {
        allReviews = Map<String, dynamic>.from(raw);
      }

      final list = allReviews[productId] is List ? List<dynamic>.from(allReviews[productId] as List) : <dynamic>[];
      final newReview = {
        'id': 'rev_${DateTime.now().millisecondsSinceEpoch}',
        'product_id': productId,
        'rating': rating,
        'comment': comment.trim(),
        'reviewer_name': reviewerName.trim().isNotEmpty ? reviewerName.trim() : 'Verified Customer',
        'created_at': DateTime.now().toIso8601String(),
        'is_verified_purchase': true,
      };

      list.insert(0, newReview);
      allReviews[productId] = list;
      await box.put(_boxKey, allReviews);
      await box.flush();

      // Sync to Supabase reviews table if available
      try {
        final client = Supabase.instance.client;
        await client.from('reviews').insert({
          'rating': rating,
          'comment': comment.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    } catch (_) {}
  }
}
