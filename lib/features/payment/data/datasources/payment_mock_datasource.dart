import '../../domain/entities/payment.dart';

class PaymentMockDataSource {
  final Map<String, Payment> _payments = {};

  static final List<PaymentMethod> _methods = [
    const PaymentMethod(
      id: '1',
      type: 'bank_transfer',
      name: 'BCA',
      accountNumber: '1234567890',
      accountName: 'Geminiflo_',
      bankCode: 'BCA',
      isActive: true,
    ),
    const PaymentMethod(
      id: '2',
      type: 'bank_transfer',
      name: 'Mandiri',
      accountNumber: '0987654321',
      accountName: 'Geminiflo_',
      bankCode: 'Mandiri',
      isActive: true,
    ),
    const PaymentMethod(
      id: '3',
      type: 'ewallet',
      name: 'GoPay',
      accountNumber: '082134567890',
      accountName: 'Geminiflo_',
      isActive: true,
    ),
    const PaymentMethod(
      id: '4',
      type: 'qris',
      name: 'QRIS',
      isActive: true,
    ),
  ];

  Future<Payment> getOrCreatePayment(String bookingId, double amount) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_payments.containsKey(bookingId)) {
      return _payments[bookingId]!;
    }
    final payment = Payment(
      id: 'pay-$bookingId',
      bookingId: bookingId,
      bookingCode: '#GF-${DateTime.now().year}-${bookingId.hashCode.abs() % 9999}',
      amount: amount,
      status: PaymentStatus.unpaid,
      deadline: DateTime.now().add(const Duration(hours: 24)),
    );
    _payments[bookingId] = payment;
    return payment;
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _methods.where((m) => m.isActive).toList();
  }

  Future<Payment> uploadProof(String bookingId, String proofPath) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final old = _payments[bookingId]!;
    final updated = Payment(
      id: old.id,
      bookingId: old.bookingId,
      bookingCode: old.bookingCode,
      amount: old.amount,
      status: PaymentStatus.waitingVerification,
      proofImageUrl: proofPath,
      paidAt: DateTime.now(),
      deadline: old.deadline,
    );
    _payments[bookingId] = updated;
    return updated;
  }
}
