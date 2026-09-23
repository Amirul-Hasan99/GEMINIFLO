import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/booking_mock_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

final bookingMockDataSourceProvider = Provider<BookingMockDataSource>((ref) {
  return BookingMockDataSource();
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(
    mock: ref.watch(bookingMockDataSourceProvider),
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

  Future<void> cancelBooking(String id, {String? reason}) async {
    final repo = ref.read(bookingRepositoryProvider);
    await repo.cancelBooking(id, reason: reason);
    await loadBookings();
  }
}

final myBookingsProvider = NotifierProvider<MyBookingsNotifier, MyBookingsState>(
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
      final mock = ref.read(bookingMockDataSourceProvider);
      final booking = await mock.createBooking(
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
      state = state.copyWith(isLoading: false, createdBooking: booking);
      // Refresh orders list (fire-and-forget; booking list will update in background)
      unawaited(ref.read(myBookingsProvider.notifier).loadBookings());
      return booking;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final createBookingProvider = NotifierProvider<CreateBookingNotifier, CreateBookingState>(
  CreateBookingNotifier.new,
);
