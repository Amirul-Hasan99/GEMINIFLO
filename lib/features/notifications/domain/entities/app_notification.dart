enum NotificationType {
  orderCreated,
  paymentWaiting,
  paymentVerified,
  paymentRejected,
  orderStatusChanged,
  orderCancelled,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  final String? bookingId;
  final String? bookingCode;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.bookingId,
    this.bookingCode,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    NotificationType? type,
    String? bookingId,
    String? bookingCode,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      bookingId: bookingId ?? this.bookingId,
      bookingCode: bookingCode ?? this.bookingCode,
      isRead: isRead ?? this.isRead,
    );
  }
}
