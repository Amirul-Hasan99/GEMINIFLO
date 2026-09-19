import '../../domain/entities/booking.dart';

class BookingMockDataSource {
  final List<Booking> _bookings = [];
  int _counter = 1000;

  Future<List<Booking>> getMyBookings({String? status}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (status != null && status.isNotEmpty) {
      return _bookings
          .where((b) => b.status.name == status)
          .toList()
          .reversed
          .toList();
    }
    return _bookings.reversed.toList();
  }

  Future<Booking> getBookingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bookings.firstWhere((b) => b.id == id);
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
    required double productPrice,
    required String productName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _counter++;
    final subtotal = productPrice;
    final deliveryFee = withDelivery ? 150000.0 : 0.0;
    final installationFee = withInstallation ? 100000.0 : 0.0;
    final total = subtotal + deliveryFee + installationFee;
    final booking = Booking(
      id: _counter.toString(),
      bookingCode: 'GF-${DateTime.now().year}-$_counter',
      productId: productId,
      productName: productName,
      customerId: 'mock-user',
      customerName: customerName,
      customerPhone: customerPhone,
      eventAddress: eventAddress,
      eventMessage: eventMessage,
      notes: notes,
      startDate: startDate,
      endDate: endDate,
      withDelivery: withDelivery,
      withInstallation: withInstallation,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      installationFee: installationFee,
      total: total,
      status: BookingStatus.pendingPayment,
      createdAt: DateTime.now(),
      paymentDeadline: DateTime.now().add(const Duration(hours: 24)),
    );
    _bookings.add(booking);
    return booking;
  }

  Future<void> cancelBooking(String id, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final old = _bookings[index];
      _bookings[index] = Booking(
        id: old.id,
        bookingCode: old.bookingCode,
        productId: old.productId,
        productName: old.productName,
        customerId: old.customerId,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        eventAddress: old.eventAddress,
        eventMessage: old.eventMessage,
        notes: old.notes,
        startDate: old.startDate,
        endDate: old.endDate,
        withDelivery: old.withDelivery,
        withInstallation: old.withInstallation,
        subtotal: old.subtotal,
        deliveryFee: old.deliveryFee,
        installationFee: old.installationFee,
        total: old.total,
        status: BookingStatus.cancelled,
        createdAt: old.createdAt,
        paymentDeadline: old.paymentDeadline,
      );
    }
  }
}
