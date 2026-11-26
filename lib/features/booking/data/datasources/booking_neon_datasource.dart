import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/booking.dart';

class BookingNeonDataSource {
  final ApiClient _client;
  BookingNeonDataSource(this._client);

  Future<List<Booking>> getBookings({String? status}) async {
    final response = await _client.get(
      ApiConstants.bookings,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    final rows = data is Map ? data['bookings'] : null;
    if (rows is! List)
      throw const FormatException(
        'Format data booking dari server tidak valid.',
      );
    return rows
        .map((row) => _fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<Booking> getBookingById(String id) async {
    final response = await _client.get(ApiConstants.bookingDetail(id));
    final data = response.data['data'];
    return _fromJson(Map<String, dynamic>.from(data['booking'] as Map));
  }

  Future<Booking> createBooking({
    required String productId,
    required DateTime startDate,
    required DateTime endDate,
    required String customerName,
    required String customerPhone,
    required String eventAddress,
    required String eventMessage,
    String? notes,
    required bool withDelivery,
    required bool withInstallation,
  }) async {
    final response = await _client.post(
      ApiConstants.bookings,
      data: {
        'product_id': productId,
        'start_date': startDate.toUtc().toIso8601String(),
        'end_date': endDate.toUtc().toIso8601String(),
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'event_address': eventAddress,
        'event_message': eventMessage,
        'notes': notes,
        'with_delivery': withDelivery,
        'with_installation': withInstallation,
      },
    );
    return _fromJson(
      Map<String, dynamic>.from(response.data['data']['booking'] as Map),
    );
  }

  Future<Booking> updateBooking(Booking booking) async {
    final response = await _client.put(
      ApiConstants.bookingDetail(booking.id),
      data: _toJson(booking),
    );
    return _fromJson(
      Map<String, dynamic>.from(response.data['data']['booking'] as Map),
    );
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async =>
      _client.put(
        ApiConstants.adminBookingUpdateStatus(id),
        data: {'status': _statusToApi(status)},
      );
  Future<void> markReturned(String id) async =>
      _client.post(ApiConstants.adminBookingReturn(id));
  Future<void> cancelBooking(String id, {String? reason}) async =>
      _client.post(ApiConstants.bookingCancel(id), data: {'reason': reason});
  Future<void> deleteBooking(String id) async =>
      _client.delete(ApiConstants.bookingDetail(id));
  static Booking _fromJson(Map<String, dynamic> j) => Booking(
    id: '${j['id']}',
    bookingCode: '${j['bookingCode'] ?? j['booking_code']}',
    productId: '${j['productId'] ?? j['product_id'] ?? ''}',
    productName: '${j['productName'] ?? j['product_name'] ?? ''}',
    productImageUrl: j['productImageUrl']?.toString(),
    customerId: '${j['customerId'] ?? j['user_id'] ?? ''}',
    customerName: '${j['customerName'] ?? j['customer_name'] ?? ''}',
    customerUsername: j['customerUsername']?.toString(),
    customerEmail: j['customerEmail']?.toString(),
    customerPhone: '${j['customerPhone'] ?? j['customer_phone'] ?? ''}',
    eventAddress: '${j['eventAddress'] ?? j['event_address'] ?? ''}',
    eventMessage: '${j['eventMessage'] ?? j['event_message'] ?? ''}',
    notes: j['notes']?.toString(),
    startDate: DateTime.parse('${j['startDate'] ?? j['start_date']}').toLocal(),
    endDate: DateTime.parse('${j['endDate'] ?? j['end_date']}').toLocal(),
    withDelivery:
        (j['withDelivery'] as bool?) ?? (j['with_delivery'] as bool?) ?? true,
    withInstallation:
        (j['withInstallation'] as bool?) ??
        (j['with_installation'] as bool?) ??
        true,
    subtotal: _number(j['subtotal'] ?? j['total_amount']),
    deliveryFee: _number(j['deliveryFee'] ?? j['delivery_fee']),
    installationFee: _number(j['installationFee'] ?? j['installation_fee']),
    total: _number(j['total'] ?? j['total_amount']),
    status: BookingStatus.fromString(
      '${j['status'] ?? j['booking_status'] ?? 'pending_payment'}',
    ),
    createdAt: DateTime.parse('${j['createdAt'] ?? j['created_at']}').toLocal(),
    paymentDeadline:
        j['paymentDeadline'] == null && j['payment_deadline'] == null
        ? null
        : DateTime.parse('${j['paymentDeadline'] ?? j['payment_deadline']}')
              .toLocal(),
    returnedAt: j['returnedAt'] == null && j['returned_at'] == null
        ? null
        : DateTime.parse('${j['returnedAt'] ?? j['returned_at']}').toLocal(),
  );
  static Map<String, dynamic> _toJson(Booking b) => {
    'product_id': b.productId,
    'start_date': b.startDate.toUtc().toIso8601String(),
    'end_date': b.endDate.toUtc().toIso8601String(),
    'customer_name': b.customerName,
    'customer_phone': b.customerPhone,
    'event_address': b.eventAddress,
    'event_message': b.eventMessage,
    'notes': b.notes,
    'with_delivery': b.withDelivery,
    'with_installation': b.withInstallation,
  };
  static String _statusToApi(BookingStatus s) => switch (s) {
    BookingStatus.pendingPayment => 'pending_payment',
    BookingStatus.confirmed => 'confirmed',
    BookingStatus.processing => 'processing',
    BookingStatus.ready => 'ready',
    BookingStatus.completed => 'completed',
    BookingStatus.cancelled => 'cancelled',
    BookingStatus.expired => 'expired',
  };
  static double _number(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
}
