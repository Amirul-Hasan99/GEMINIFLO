import 'package:flutter_test/flutter_test.dart';
import 'package:geminiflo_booking/features/payment/data/datasources/payment_mock_datasource.dart';
import 'package:geminiflo_booking/features/payment/domain/entities/payment.dart';

void main() {
  late PaymentMockDataSource dataSource;

  setUp(() {
    dataSource = PaymentMockDataSource();
  });

  group('PaymentMockDataSource (CRUD)', () {
    test('getPaymentMethods returns active methods', () async {
      final methods = await dataSource.getPaymentMethods();
      expect(methods, isNotEmpty);
      expect(methods.every((m) => m.isActive), isTrue);
    });

    test('getOrCreatePayment creates a new payment if not exists', () async {
      final bookingId = 'test-booking-1';
      final amount = 500000.0;

      final payment = await dataSource.getOrCreatePayment(bookingId, amount);
      expect(payment.bookingId, bookingId);
      expect(payment.amount, amount);
      expect(payment.status, PaymentStatus.unpaid);

      // Requesting again should return the exact same payment object
      final payment2 = await dataSource.getOrCreatePayment(bookingId, amount);
      expect(payment2.id, payment.id);
    });

    test('uploadProof updates payment status to waitingVerification', () async {
      final bookingId = 'test-booking-2';
      final amount = 200000.0;

      await dataSource.getOrCreatePayment(bookingId, amount);

      final updated = await dataSource.uploadProof(bookingId, '/path/to/proof.jpg');
      expect(updated.status, PaymentStatus.waitingVerification);
      expect(updated.proofImageUrl, '/path/to/proof.jpg');
      expect(updated.paidAt, isNotNull);
    });

    test('deletePayment removes payment from datasource', () async {
      final bookingId = 'test-booking-delete';
      final payment = await dataSource.getOrCreatePayment(bookingId, 300000.0);
      expect(await dataSource.getPaymentById(payment.id), isNotNull);

      final success = await dataSource.deletePayment(payment.id);
      expect(success, isTrue);

      final deleted = await dataSource.getPaymentById(payment.id);
      expect(deleted, isNull);
    });
  });
}
