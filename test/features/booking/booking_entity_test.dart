import 'package:flutter_test/flutter_test.dart';
import 'package:geminiflo_booking/features/booking/domain/entities/booking.dart';

void main() {
  group('BookingStatus Enum Tests', () {
    test('fromString parses all standard status strings correctly', () {
      expect(BookingStatus.fromString('pending_payment'), BookingStatus.pendingPayment);
      expect(BookingStatus.fromString('confirmed'), BookingStatus.confirmed);
      expect(BookingStatus.fromString('processing'), BookingStatus.processing);
      expect(BookingStatus.fromString('ready'), BookingStatus.ready);
      expect(BookingStatus.fromString('completed'), BookingStatus.completed);
      expect(BookingStatus.fromString('cancelled'), BookingStatus.cancelled);
      expect(BookingStatus.fromString('expired'), BookingStatus.expired);
      expect(BookingStatus.fromString('unknown_status'), BookingStatus.pendingPayment);
    });

    test('label returns expected Indonesian localization string', () {
      expect(BookingStatus.pendingPayment.label, 'Menunggu Pembayaran');
      expect(BookingStatus.confirmed.label, 'Dikonfirmasi');
      expect(BookingStatus.processing.label, 'Diproses');
      expect(BookingStatus.ready.label, 'Siap');
      expect(BookingStatus.completed.label, 'Selesai');
      expect(BookingStatus.cancelled.label, 'Dibatalkan');
      expect(BookingStatus.expired.label, 'Kadaluarsa');
    });
  });

  group('Booking Pricing and Calculation Tests', () {
    test('Booking model maintains proper financial values', () {
      final now = DateTime.now();
      final booking = Booking(
        id: 'bk-001',
        bookingCode: 'GF-2026-001',
        productId: 'prod-101',
        productName: 'Romantic Rose Garland',
        customerId: 'cust-1',
        customerName: 'Jane Doe',
        customerPhone: '08123456789',
        eventAddress: 'Jl. Melati No. 10',
        eventMessage: 'Happy Birthday!',
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        withDelivery: true,
        withInstallation: true,
        subtotal: 500000.0,
        deliveryFee: 50000.0,
        installationFee: 75000.0,
        total: 625000.0,
        status: BookingStatus.pendingPayment,
        createdAt: now,
      );

      expect(booking.total, equals(booking.subtotal + booking.deliveryFee + booking.installationFee));
      expect(booking.withDelivery, isTrue);
      expect(booking.withInstallation, isTrue);
      expect(booking.bookingCode, 'GF-2026-001');
    });
  });
}
