import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/review.dart';

class ReviewDataSource {
  ReviewDataSource(this._client);
  final ApiClient _client;

  Future<List<Review>> getProductReviews(String productId) async {
    final response = await _client.get(ApiConstants.productReviews(productId));
    return _parseRows(response.data);
  }

  Future<List<Review>> getAdminReviews() async {
    final response = await _client.get(ApiConstants.adminReviews);
    return _parseRows(response.data);
  }

  Future<Map<String, dynamic>?> getBookingReview(String bookingId) async {
    final response = await _client.get(ApiConstants.bookingReview(bookingId));
    final data = response.data['data'];
    return data is Map && data['review'] is Map
        ? Map<String, dynamic>.from(data['review'] as Map)
        : null;
  }

  Future<void> submit({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    await _client.post(
      ApiConstants.bookingReview(bookingId),
      data: {'rating': rating, 'comment': comment},
    );
  }

  List<Review> _parseRows(dynamic response) {
    final data = response is Map ? response['data'] : null;
    final rows = data is Map
        ? data['reviews']
        : response is Map
        ? response['reviews']
        : null;
    if (rows is! List)
      throw const FormatException('Format daftar ulasan tidak valid.');
    return rows
        .map((row) => Review.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}
