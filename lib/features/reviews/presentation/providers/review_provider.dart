import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/review_datasource.dart';
import '../../domain/review.dart';

final reviewDataSourceProvider = Provider<ReviewDataSource>(
  (ref) => ReviewDataSource(ref.watch(apiClientProvider)),
);

final productReviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, productId) =>
      ref.watch(reviewDataSourceProvider).getProductReviews(productId),
);

final adminReviewsProvider = FutureProvider<List<Review>>(
  (ref) => ref.watch(reviewDataSourceProvider).getAdminReviews(),
);

final bookingReviewProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
      (ref, bookingId) =>
          ref.watch(reviewDataSourceProvider).getBookingReview(bookingId),
    );
