import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payment.dart';
import '../../data/datasources/payment_mock_datasource.dart';

final paymentMockDataSourceProvider = Provider<PaymentMockDataSource>((ref) {
  return PaymentMockDataSource();
});

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
  }) {
    return PaymentState(
      payment: payment ?? this.payment,
      methods: methods ?? this.methods,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedMethodIndex: selectedMethodIndex ?? this.selectedMethodIndex,
    );
  }
}

// Riverpod 3: use a regular Notifier + store the arg at build time
class PaymentNotifier extends Notifier<PaymentState> {
  late String _bookingId;
  late double _amount;

  @override
  PaymentState build() {
    // Retrieve arg from the provider — callers must use paymentProvider(args)
    // We cannot use FamilyNotifier because of generics limitations with Maps;
    // instead, expose a separate initialise method called from the screen.
    return const PaymentState();
  }

  Future<void> initialise({required String bookingId, required double amount}) async {
    _bookingId = bookingId;
    _amount = amount;
    state = state.copyWith(isLoading: true);
    final mock = ref.read(paymentMockDataSourceProvider);
    try {
      final payment = await mock.getOrCreatePayment(_bookingId, _amount);
      final methods = await mock.getPaymentMethods();
      state = state.copyWith(payment: payment, methods: methods, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectMethod(int index) {
    state = state.copyWith(selectedMethodIndex: index);
  }

  Future<bool> uploadProof(String imagePath) async {
    state = state.copyWith(isLoading: true);
    try {
      final mock = ref.read(paymentMockDataSourceProvider);
      final updated = await mock.uploadProof(_bookingId, imagePath);
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
