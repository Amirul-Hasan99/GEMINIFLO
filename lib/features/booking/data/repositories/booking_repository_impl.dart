import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_mock_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingMockDataSource mock;
  final String productName;
  final double productPrice;

  BookingRepositoryImpl({
    required this.mock,
    this.productName = '',
    this.productPrice = 0,
  });

  @override
  Future<List<Booking>> getMyBookings({String? status}) =>
      mock.getMyBookings(status: status);

  @override
  Future<Booking> getBookingById(String id) => mock.getBookingById(id);

  @override
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
  }) =>
      mock.createBooking(
        productId: productId,
        startDate: startDate,
        endDate: endDate,
        customerName: customerName,
        customerPhone: customerPhone,
        eventAddress: eventAddress,
        eventMessage: eventMessage,
        notes: notes,
        withDelivery: withDelivery,
        withInstallation: withInstallation,
        productPrice: productPrice,
        productName: productName,
      );

  @override
  Future<void> cancelBooking(String id, {String? reason}) =>
      mock.cancelBooking(id, reason: reason);
}
