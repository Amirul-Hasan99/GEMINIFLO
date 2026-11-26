import '../../domain/entities/payment.dart';

class PaymentMockDataSource {
  // Shared static storage so user uploads are visible to admin
  // Keep mock payments empty so sample transactions are never presented as real.
  static final Map<String, Payment> _payments = {};

  // QRIS removed per user request: Only BCA, Mandiri, and GoPay
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
  ];

  Future<Payment> getOrCreatePayment(String bookingId, double amount) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_payments.containsKey(bookingId)) {
      final existing = _payments[bookingId]!;
      if (existing.amount == 0.0 && amount > 0) {
        final updated = Payment(
          id: existing.id,
          bookingId: existing.bookingId,
          bookingCode: existing.bookingCode,
          amount: amount,
          status: existing.status,
          proofImageUrl: existing.proofImageUrl,
          paidAt: existing.paidAt,
          verifiedAt: existing.verifiedAt,
          rejectionReason: existing.rejectionReason,
          deadline: existing.deadline,
        );
        _payments[bookingId] = updated;
        return updated;
      }
      return existing;
    }

    final payment = Payment(
      id: 'pay-$bookingId',
      bookingId: bookingId,
      bookingCode: 'GF-${DateTime.now().year}-$bookingId',
      amount: amount,
      status: PaymentStatus.unpaid,
      deadline: DateTime.now().add(const Duration(hours: 24)),
    );
    _payments[bookingId] = payment;
    return payment;
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _methods.where((m) => m.isActive).toList();
  }

  Future<Payment> uploadProof(String bookingId, String? proofPath) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final old =
        _payments[bookingId] ??
        Payment(
          id: 'pay-$bookingId',
          bookingId: bookingId,
          bookingCode: 'GF-${DateTime.now().year}-$bookingId',
          amount: 0.0,
          status: PaymentStatus.unpaid,
          deadline: DateTime.now().add(const Duration(hours: 24)),
        );

    final updated = Payment(
      id: old.id,
      bookingId: old.bookingId,
      bookingCode: old.bookingCode,
      amount: old.amount,
      status: PaymentStatus.waitingVerification,
      proofImageUrl: proofPath?.isNotEmpty == true ? proofPath : null,
      paidAt: DateTime.now(),
      deadline: old.deadline,
    );
    _payments[bookingId] = updated;
    return updated;
  }

  Future<List<Payment>> getAllPayments({PaymentStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = _payments.values.toList();
    if (status != null) {
      return list.where((p) => p.status == status).toList().reversed.toList();
    }
    return list.reversed.toList();
  }

  Future<Payment?> getPaymentById(String paymentOrBookingId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_payments.containsKey(paymentOrBookingId)) {
      return _payments[paymentOrBookingId];
    }
    try {
      return _payments.values.firstWhere(
        (p) => p.id == paymentOrBookingId || p.bookingId == paymentOrBookingId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Payment> verifyPayment(
    String paymentOrBookingId,
    bool approve, {
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final payment = await getPaymentById(paymentOrBookingId);
    if (payment == null) {
      throw Exception('Pembayaran tidak ditemukan');
    }

    final updated = Payment(
      id: payment.id,
      bookingId: payment.bookingId,
      bookingCode: payment.bookingCode,
      amount: payment.amount,
      status: approve ? PaymentStatus.verified : PaymentStatus.rejected,
      proofImageUrl: payment.proofImageUrl,
      paidAt: payment.paidAt,
      verifiedAt: approve ? DateTime.now() : null,
      rejectionReason: approve
          ? null
          : (reason ?? 'Bukti pembayaran tidak sesuai mutasi'),
      deadline: payment.deadline,
    );

    _payments[payment.bookingId] = updated;
    return updated;
  }

  Future<bool> deletePayment(String paymentOrBookingId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_payments.containsKey(paymentOrBookingId)) {
      _payments.remove(paymentOrBookingId);
      return true;
    }
    final key = _payments.keys.cast<String?>().firstWhere(
      (k) => _payments[k]?.id == paymentOrBookingId,
      orElse: () => null,
    );
    if (key != null) {
      _payments.remove(key);
      return true;
    }
    return false;
  }
}
