import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/booking_neon_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';

final bookingNeonDataSourceProvider = Provider<BookingNeonDataSource>((ref) {
  return BookingNeonDataSource(ref.watch(apiClientProvider));
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(
    remote: ref.watch(bookingNeonDataSourceProvider),
  );
});

// My bookings list state
class MyBookingsState {
  final List<Booking> bookings;
  final bool isLoading;
  final String? error;

  const MyBookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  MyBookingsState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return MyBookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Riverpod 3: Notifier
class MyBookingsNotifier extends Notifier<MyBookingsState> {
  @override
  MyBookingsState build() {
    Future.microtask(() => loadBookings());
    return const MyBookingsState();
  }

  Future<void> loadBookings({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final bookings = await repo.getMyBookings(status: status);
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _refreshAvailability(String? productId) {
    unawaited(ref.read(catalogProvider.notifier).loadProducts());
    if (productId != null && productId.isNotEmpty) {
      ref.invalidate(productDetailProvider(productId));
    }
  }

  Future<void> cancelBooking(String id, {String? reason}) async {
    final productId = state.bookings.where((b) => b.id == id).firstOrNull?.productId;
    final repo = ref.read(bookingRepositoryProvider);
    await repo.cancelBooking(id, reason: reason);
    await loadBookings();
    _refreshAvailability(productId);
    unawaited(
      ref
          .read(notificationProvider.notifier)
          .addNotification(
            title: 'Pesanan Dibatalkan',
            message: 'Pesanan #$id telah dibatalkan.',
            type: NotificationType.orderCancelled,
            bookingId: id,
          ),
    );
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    final productId = state.bookings.where((b) => b.id == id).firstOrNull?.productId;
    await ref.read(bookingRepositoryProvider).updateBookingStatus(id, status);
    await loadBookings();
    _refreshAvailability(productId);
  }

  Future<void> markReturned(String id) async {
    final productId = state.bookings.where((b) => b.id == id).firstOrNull?.productId;
    await ref.read(bookingRepositoryProvider).markReturned(id);
    await loadBookings();
    _refreshAvailability(productId);
  }

  Future<void> deleteBooking(String id) async {
    final productId = state.bookings.where((b) => b.id == id).firstOrNull?.productId;
    await ref.read(bookingRepositoryProvider).deleteBooking(id);
    await loadBookings();
    _refreshAvailability(productId);
  }

  Future<Booking> updateBooking(Booking booking) async {
    final updated = await ref
        .read(bookingRepositoryProvider)
        .updateBooking(booking);
    await loadBookings();
    _refreshAvailability(booking.productId);
    unawaited(
      ref
          .read(notificationProvider.notifier)
          .addNotification(
            title: 'Pesanan Diperbarui',
            message:
                'Rincian pesanan ${booking.bookingCode} berhasil diperbarui.',
            type: NotificationType.orderStatusChanged,
            bookingId: booking.id,
            bookingCode: booking.bookingCode,
          ),
    );
    return updated;
  }
}

final myBookingsProvider =
    NotifierProvider<MyBookingsNotifier, MyBookingsState>(
      MyBookingsNotifier.new,
    );

// Create booking state
class CreateBookingState {
  final bool isLoading;
  final Booking? createdBooking;
  final String? error;

  const CreateBookingState({
    this.isLoading = false,
    this.createdBooking,
    this.error,
  });

  CreateBookingState copyWith({
    bool? isLoading,
    Booking? createdBooking,
    String? error,
  }) {
    return CreateBookingState(
      isLoading: isLoading ?? this.isLoading,
      createdBooking: createdBooking ?? this.createdBooking,
      error: error,
    );
  }
}

// Riverpod 3: Notifier
class CreateBookingNotifier extends Notifier<CreateBookingState> {
  @override
  CreateBookingState build() => const CreateBookingState();

  Future<Booking?> createBooking({
    required String productId,
    required String productName,
    required double productPrice,
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final booking = await ref
          .read(bookingRepositoryProvider)
          .createBooking(
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
            productName: productName,
            productPrice: productPrice,
          );
      state = state.copyWith(isLoading: false, createdBooking: booking);
      unawaited(ref.read(catalogProvider.notifier).loadProducts());
      ref.invalidate(productDetailProvider(productId));
      // Refresh orders list (fire-and-forget; booking list will update in background)
      unawaited(ref.read(myBookingsProvider.notifier).loadBookings());
      unawaited(
        ref
            .read(notificationProvider.notifier)
            .addNotification(
              title: 'Pesanan Berhasil Dibuat',
              message:
                  'Pesanan #${booking.bookingCode} untuk $productName berhasil dibuat. Silakan selesaikan pembayaran.',
              type: NotificationType.orderCreated,
              bookingId: booking.id,
              bookingCode: booking.bookingCode,
            ),
      );
      return booking;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final createBookingProvider =
    NotifierProvider<CreateBookingNotifier, CreateBookingState>(
      CreateBookingNotifier.new,
    );
