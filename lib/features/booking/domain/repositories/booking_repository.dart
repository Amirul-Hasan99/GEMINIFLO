import '../entities/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> getMyBookings({String? status});
  Future<Booking> getBookingById(String id);
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
  });
  Future<void> cancelBooking(String id, {String? reason});
}
