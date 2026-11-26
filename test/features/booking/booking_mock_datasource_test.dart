import 'package:flutter_test/flutter_test.dart';
import 'package:geminiflo_booking/features/booking/data/datasources/booking_mock_datasource.dart';
import 'package:geminiflo_booking/features/booking/domain/entities/booking.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late BookingMockDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BookingMockDataSource.resetForTesting();
    dataSource = BookingMockDataSource();
  });

  group('BookingMockDataSource (CRUD)', () {
    test(
      'createBooking adds a booking and calculates totals correctly',
      () async {
        final booking = await dataSource.createBooking(
          productId: '1',
          productName: 'Papan Bunga Test',
          productPrice: 100000.0,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 1)),
          customerName: 'Test User',
          customerPhone: '081234567890',
          eventAddress: 'Jl. Test Address',
          eventMessage: 'Happy Wedding',
          withDelivery: true,
          withInstallation: true,
        );

        expect(booking.id, isNotNull);
        expect(booking.productName, 'Papan Bunga Test');
        expect(booking.subtotal, 100000.0);
        expect(booking.deliveryFee, 0.0);
        expect(booking.installationFee, 0.0);
        expect(booking.total, 100000.0);
        expect(booking.status, BookingStatus.pendingPayment);

        // Verify it was added
        final bookings = await dataSource.getMyBookings();
        expect(bookings, isNotEmpty);
        expect(bookings.first.id, booking.id);
      },
    );

    test('getBookingById returns the correct booking', () async {
      final created = await dataSource.createBooking(
        productId: '2',
        productName: 'Papan Bunga 2',
        productPrice: 50000.0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        customerName: 'Test User',
        customerPhone: '081234567890',
        eventAddress: 'Jl. Test Address',
        eventMessage: 'Congratulations',
        withDelivery: false,
        withInstallation: false,
      );

      final fetched = await dataSource.getBookingById(created.id);
      expect(fetched.id, created.id);
      expect(fetched.total, 50000.0);
    });

    test('cancelBooking updates status to cancelled', () async {
      final created = await dataSource.createBooking(
        productId: '3',
        productName: 'Papan Bunga 3',
        productPrice: 50000.0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        customerName: 'Test User',
        customerPhone: '081234567890',
        eventAddress: 'Jl. Test Address',
        eventMessage: 'Congratulations',
        withDelivery: false,
        withInstallation: false,
      );

      await dataSource.cancelBooking(created.id, reason: 'Test reason');
      final fetched = await dataSource.getBookingById(created.id);

      expect(fetched.status, BookingStatus.cancelled);
    });

    test(
      'user can edit a pending booking and the history survives reload',
      () async {
        final created = await dataSource.createBooking(
          productId: '3',
          productName: 'Kubah Pink',
          productPrice: 80000,
          startDate: DateTime.now().add(const Duration(days: 2)),
          endDate: DateTime.now().add(const Duration(days: 3)),
          customerName: 'Nama Lama',
          customerPhone: '081234567890',
          eventAddress: 'Alamat Lama',
          eventMessage: 'Ucapan Lama',
          withDelivery: true,
          withInstallation: true,
        );
        final edited = Booking(
          id: created.id,
          bookingCode: created.bookingCode,
          productId: created.productId,
          productName: created.productName,
          customerId: created.customerId,
          customerName: 'Nama Baru',
          customerPhone: created.customerPhone,
          eventAddress: 'Alamat Baru',
          eventMessage: 'Ucapan Baru',
          startDate: created.startDate,
          endDate: created.endDate,
          withDelivery: false,
          withInstallation: false,
          subtotal: created.subtotal,
          deliveryFee: 0,
          installationFee: 0,
          total: created.total,
          status: created.status,
          createdAt: created.createdAt,
          paymentDeadline: created.paymentDeadline,
        );

        await dataSource.updateBooking(edited);
        final reloaded = await BookingMockDataSource().getBookingById(
          created.id,
        );
        expect(reloaded.customerName, 'Nama Baru');
        expect(reloaded.eventAddress, 'Alamat Baru');
        expect(reloaded.withDelivery, isFalse);
      },
    );
  });
}
