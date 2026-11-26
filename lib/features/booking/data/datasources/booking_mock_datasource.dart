import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/booking.dart';

class BookingMockDataSource {
  static const String _storageKey = 'geminiflo.bookings.v1';
  static final List<Booking> _seedBookings = [];
  static final List<Booking> _bookings = List<Booking>.of(_seedBookings);
  static int _counter = 1002;
  static Future<void>? _loadFuture;

  static Future<void> resetForTesting() async {
    _loadFuture = null;
    _bookings
      ..clear()
      ..addAll(_seedBookings);
    _counter = 1002;
  }

  static Future<void> _ensureLoaded() async {
    _loadFuture ??= _restore();
    await _loadFuture;
  }

  static Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved == null) return;
    try {
      final rows = jsonDecode(saved) as List<dynamic>;
      _bookings
        ..clear()
        ..addAll(rows.map((row) => _fromJson(row as Map<String, dynamic>)));
      final ids = _bookings.map((booking) => int.tryParse(booking.id) ?? 0);
      _counter = ids.fold<int>(_counter, (max, id) => id > max ? id : max);
    } on Object {
      _bookings
        ..clear()
        ..addAll(_seedBookings);
      await _save();
    }
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_bookings.map(_toJson).toList()),
    );
  }

  static Map<String, dynamic> _toJson(Booking booking) => {
    'id': booking.id,
    'bookingCode': booking.bookingCode,
    'productId': booking.productId,
    'productName': booking.productName,
    'productImageUrl': booking.productImageUrl,
    'customerId': booking.customerId,
    'customerName': booking.customerName,
    'customerUsername': booking.customerUsername,
    'customerEmail': booking.customerEmail,
    'customerPhone': booking.customerPhone,
    'eventAddress': booking.eventAddress,
    'eventMessage': booking.eventMessage,
    'notes': booking.notes,
    'startDate': booking.startDate.toIso8601String(),
    'endDate': booking.endDate.toIso8601String(),
    'withDelivery': booking.withDelivery,
    'withInstallation': booking.withInstallation,
    'subtotal': booking.subtotal,
    'deliveryFee': booking.deliveryFee,
    'installationFee': booking.installationFee,
    'total': booking.total,
    'status': booking.status.name,
    'createdAt': booking.createdAt.toIso8601String(),
    'paymentDeadline': booking.paymentDeadline?.toIso8601String(),
  };

  static Booking _fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as String,
    bookingCode: json['bookingCode'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    productImageUrl: json['productImageUrl'] as String?,
    customerId: json['customerId'] as String,
    customerName: json['customerName'] as String,
    customerUsername: json['customerUsername'] as String?,
    customerEmail: json['customerEmail'] as String?,
    customerPhone: json['customerPhone'] as String,
    eventAddress: json['eventAddress'] as String,
    eventMessage: json['eventMessage'] as String,
    notes: json['notes'] as String?,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    withDelivery: json['withDelivery'] as bool,
    withInstallation: json['withInstallation'] as bool,
    subtotal: (json['subtotal'] as num).toDouble(),
    deliveryFee: (json['deliveryFee'] as num).toDouble(),
    installationFee: (json['installationFee'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    status: BookingStatus.values.firstWhere(
      (status) => status.name == json['status'],
      orElse: () => BookingStatus.pendingPayment,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    paymentDeadline: json['paymentDeadline'] == null
        ? null
        : DateTime.parse(json['paymentDeadline'] as String),
  );

  Future<List<Booking>> getMyBookings({String? status}) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 300));
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
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 200));
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
    double? customDeliveryFee,
    double? customInstallationFee,
    required double productPrice,
    required String productName,
  }) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 500));
    _counter++;
    final subtotal = productPrice;
    final deliveryFee = customDeliveryFee ?? 0.0;
    final installationFee = customInstallationFee ?? 0.0;
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
    await _save();
    return booking;
  }

  Future<void> cancelBooking(String id, {String? reason}) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 200));
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
        customerUsername: old.customerUsername,
        customerEmail: old.customerEmail,
        customerPhone: old.customerPhone,
        eventAddress: old.eventAddress,
        eventMessage: old.eventMessage,
        notes: reason ?? old.notes,
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
      await _save();
    }
  }

  Future<void> updateBookingStatus(String id, BookingStatus newStatus) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 200));
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
        customerUsername: old.customerUsername,
        customerEmail: old.customerEmail,
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
        status: newStatus,
        createdAt: old.createdAt,
        paymentDeadline: old.paymentDeadline,
      );
      await _save();
    }
  }

  Future<void> deleteBooking(String id) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 200));
    final initialLength = _bookings.length;
    _bookings.removeWhere((booking) => booking.id == id);
    if (_bookings.length == initialLength) {
      throw StateError('Riwayat booking tidak ditemukan.');
    }
    await _save();
  }

  Future<Booking> updateBooking(Booking booking) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _bookings.indexWhere((item) => item.id == booking.id);
    if (index == -1) throw StateError('Pesanan tidak ditemukan.');
    if (_bookings[index].status != BookingStatus.pendingPayment) {
      throw StateError('Pesanan yang sudah diproses tidak dapat diubah.');
    }
    _bookings[index] = booking;
    await _save();
    return booking;
  }
}
