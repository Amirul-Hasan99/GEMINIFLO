import '../entities/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> getMyBookings({String? status});
  Future<Booking> getBookingById(String id);
  Future<Booking> updateBooking(Booking booking);
  Future<void> deleteBooking(String id);
  Future<void> updateBookingStatus(String id, BookingStatus status);
  Future<void> markReturned(String id);
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
  });
  Future<void> cancelBooking(String id, {String? reason});
}
