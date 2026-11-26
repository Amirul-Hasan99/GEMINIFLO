class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.productId,
    required this.customerName,
    required this.productName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String productId;
  final String customerName;
  final String productName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: '${json['id'] ?? ''}',
    bookingId: '${json['booking_id'] ?? json['bookingId'] ?? ''}',
    productId: '${json['product_id'] ?? json['productId'] ?? ''}',
    customerName:
        '${json['customer_name'] ?? json['customerName'] ?? 'Pelanggan'}',
    productName: '${json['product_name'] ?? json['productName'] ?? ''}',
    rating:
        (json['rating'] as num?)?.toInt() ??
        int.tryParse('${json['rating']}') ??
        0,
    comment: '${json['comment'] ?? ''}',
    createdAt:
        DateTime.tryParse('${json['created_at'] ?? json['createdAt']}')
            ?.toLocal() ??
        DateTime.now(),
  );
}
