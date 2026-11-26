import '../datasources/booking_neon_datasource.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingNeonDataSource remote;
  BookingRepositoryImpl({required this.remote});
  @override
  Future<List<Booking>> getMyBookings({String? status}) =>
      remote.getBookings(status: status);
  @override
  Future<Booking> getBookingById(String id) => remote.getBookingById(id);
  @override
  Future<Booking> updateBooking(Booking booking) =>
      remote.updateBooking(booking);
  @override
  Future<void> deleteBooking(String id) => remote.deleteBooking(id);
  @override
  Future<void> updateBookingStatus(String id, BookingStatus status) =>
      remote.updateBookingStatus(id, status);
  @override
  Future<void> markReturned(String id) => remote.markReturned(id);
  @override
  Future<void> cancelBooking(String id, {String? reason}) =>
      remote.cancelBooking(id, reason: reason);
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
    String? productName,
    double? productPrice,
  }) => remote.createBooking(
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
  );
}
