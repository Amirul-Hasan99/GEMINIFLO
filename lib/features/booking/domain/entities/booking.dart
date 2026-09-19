enum BookingStatus {
  pendingPayment,
  confirmed,
  processing,
  ready,
  completed,
  cancelled,
  expired;

  String get label {
    switch (this) {
      case BookingStatus.pendingPayment:
        return 'Menunggu Pembayaran';
      case BookingStatus.confirmed:
        return 'Dikonfirmasi';
      case BookingStatus.processing:
        return 'Diproses';
      case BookingStatus.ready:
        return 'Siap';
      case BookingStatus.completed:
        return 'Selesai';
      case BookingStatus.cancelled:
        return 'Dibatalkan';
      case BookingStatus.expired:
        return 'Kadaluarsa';
    }
  }

  static BookingStatus fromString(String value) {
    switch (value) {
      case 'pending_payment':
        return BookingStatus.pendingPayment;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'processing':
        return BookingStatus.processing;
      case 'ready':
        return BookingStatus.ready;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'expired':
        return BookingStatus.expired;
      default:
        return BookingStatus.pendingPayment;
    }
  }
}

class Booking {
  final String id;
  final String bookingCode;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String eventAddress;
  final String eventMessage;
  final String? notes;
  final DateTime startDate;
  final DateTime endDate;
  final bool withDelivery;
  final bool withInstallation;
  final double subtotal;
  final double deliveryFee;
  final double installationFee;
  final double total;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? paymentDeadline;

  const Booking({
    required this.id,
    required this.bookingCode,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.eventAddress,
    required this.eventMessage,
    this.notes,
    required this.startDate,
    required this.endDate,
    required this.withDelivery,
    required this.withInstallation,
    required this.subtotal,
    required this.deliveryFee,
    required this.installationFee,
    required this.total,
    required this.status,
    required this.createdAt,
    this.paymentDeadline,
  });
}
