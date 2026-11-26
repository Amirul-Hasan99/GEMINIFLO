import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../data/datasources/payment_neon_datasource.dart';
import '../../domain/entities/payment.dart';

final paymentNeonDataSourceProvider = Provider<PaymentNeonDataSource>(
  (ref) => PaymentNeonDataSource(ref.watch(apiClientProvider)),
);

class PaymentState {
  final Payment? payment;
  final List<PaymentMethod> methods;
  final bool isLoading;
  final String? error;
  final int selectedMethodIndex;
  const PaymentState({
    this.payment,
    this.methods = const [],
    this.isLoading = false,
    this.error,
    this.selectedMethodIndex = 0,
  });
  PaymentState copyWith({
    Payment? payment,
    List<PaymentMethod>? methods,
    bool? isLoading,
    String? error,
    int? selectedMethodIndex,
  }) => PaymentState(
    payment: payment ?? this.payment,
    methods: methods ?? this.methods,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    selectedMethodIndex: selectedMethodIndex ?? this.selectedMethodIndex,
  );
}

class PaymentNotifier extends Notifier<PaymentState> {
  late String _bookingId;
  @override
  PaymentState build() => const PaymentState();
  Future<void> initialise({
    required String bookingId,
    required double amount,
  }) async {
    _bookingId = bookingId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final remote = ref.read(paymentNeonDataSourceProvider);
      final data = await Future.wait([
        remote.getForBooking(bookingId),
        remote.getMethods(),
      ]);
      state = state.copyWith(
        payment: data[0] as Payment,
        methods: data[1] as List<PaymentMethod>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectMethod(int index) =>
      state = state.copyWith(selectedMethodIndex: index);
  Future<bool> uploadProof(String? imageDataUri) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (imageDataUri == null || state.methods.isEmpty)
        throw StateError(
          'Metode pembayaran belum dikonfigurasi atau bukti belum dipilih.',
        );
      final method =
          state.methods[state.selectedMethodIndex.clamp(
            0,
            state.methods.length - 1,
          )];
      final remote = ref.read(paymentNeonDataSourceProvider);
      await remote.chooseMethod(_bookingId, method.id);
      final updated = await remote.uploadProof(_bookingId, imageDataUri);
      unawaited(ref.read(myBookingsProvider.notifier).loadBookings());
      unawaited(
        ref
            .read(notificationProvider.notifier)
            .addNotification(
              title: 'Bukti Pembayaran Terkirim',
              message:
                  'Bukti pembayaran booking #${updated.bookingCode} telah tersimpan dan menunggu verifikasi.',
              type: NotificationType.paymentWaiting,
              bookingId: _bookingId,
              bookingCode: updated.bookingCode,
            ),
      );
      state = state.copyWith(payment: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final paymentProvider = NotifierProvider<PaymentNotifier, PaymentState>(
  PaymentNotifier.new,
);

class AdminPaymentsState {
  final List<Payment> payments;
  final bool isLoading;
  final String? error;
  final PaymentStatus? filterStatus;
  const AdminPaymentsState({
    this.payments = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus,
  });
  AdminPaymentsState copyWith({
    List<Payment>? payments,
    bool? isLoading,
    String? error,
    PaymentStatus? filterStatus,
    bool clearFilter = false,
  }) => AdminPaymentsState(
    payments: payments ?? this.payments,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
  );
}

class AdminPaymentsNotifier extends Notifier<AdminPaymentsState> {
  @override
  AdminPaymentsState build() {
    Future.microtask(loadPayments);
    return const AdminPaymentsState(isLoading: true);
  }

  Future<void> loadPayments({PaymentStatus? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final all = await ref
          .read(paymentNeonDataSourceProvider)
          .getAdminPayments();
      final filter = status ?? state.filterStatus;
      state = state.copyWith(
        payments: filter == null
            ? all
            : all.where((p) => p.status == filter).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(PaymentStatus? status) {
    state = status == null
        ? state.copyWith(clearFilter: true)
        : state.copyWith(filterStatus: status);
    loadPayments(status: status);
  }

  Future<bool> verifyPayment(String id, bool approve, {String? reason}) async {
    try {
      await ref
          .read(paymentNeonDataSourceProvider)
          .verify(id, approve, reason: reason);
      await loadPayments();
      await ref.read(myBookingsProvider.notifier).loadBookings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePayment(String id) async {
    try {
      await ref.read(paymentNeonDataSourceProvider).delete(id);
      await loadPayments();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminPaymentsListProvider =
    NotifierProvider<AdminPaymentsNotifier, AdminPaymentsState>(
      AdminPaymentsNotifier.new,
    );
final adminPaymentsProvider = FutureProvider.autoDispose<List<Payment>>(
  (ref) => ref.watch(paymentNeonDataSourceProvider).getAdminPayments(),
);
