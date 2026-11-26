import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/payment.dart';

class PaymentNeonDataSource {
  final ApiClient client;
  PaymentNeonDataSource(this.client);

  Future<Payment> getForBooking(String bookingId) async {
    final r = await client.get(ApiConstants.bookingPayment(bookingId));
    return _payment(r.data['data']['payment'] as Map);
  }

  Future<List<PaymentMethod>> getMethods() async {
    final r = await client.get(ApiConstants.paymentMethods);
    final rows = (r.data['methods'] as List? ?? const []);
    return rows.map((x) {
      final j = Map<String, dynamic>.from(x as Map);
      return PaymentMethod(
        id: '${j['id']}',
        type: '${j['type']}',
        name: '${j['name']}',
        accountNumber: j['accountNumber']?.toString(),
        accountName: j['accountName']?.toString(),
        bankCode: j['bankCode']?.toString(),
        logoUrl: j['logoUrl']?.toString(),
        isActive: j['isActive'] as bool? ?? true,
      );
    }).toList();
  }

  Future<Payment> chooseMethod(String bookingId, String methodId) async {
    final r = await client.post(
      ApiConstants.bookingPayment(bookingId),
      data: {'payment_method': methodId},
    );
    return _payment(r.data['data']['payment'] as Map);
  }

  Future<Payment> uploadProof(String paymentId, String dataUri) async {
    final r = await client.post(
      ApiConstants.paymentProof(paymentId),
      data: {'proof': dataUri},
    );
    return _payment(r.data['data']['payment'] as Map);
  }

  Future<List<Payment>> getAdminPayments() async {
    final r = await client.get(ApiConstants.adminPayments);
    return (r.data['data']['payments'] as List)
        .map((x) => _payment(x as Map))
        .toList();
  }

  Future<Payment> getAdminPayment(String id) async {
    final r = await client.get(ApiConstants.adminPaymentDetail(id));
    return _payment(r.data['data']['payment'] as Map);
  }

  Future<void> verify(String id, bool approve, {String? reason}) async {
    await client.put(
      ApiConstants.adminPaymentVerify(id),
      data: {'approve': approve, 'reason': reason},
    );
  }

  Future<void> delete(String id) async {
    await client.delete(ApiConstants.adminPaymentDetail(id));
  }

  static Payment _payment(Map raw) {
    final j = Map<String, dynamic>.from(raw);
    final status = PaymentStatus.fromString('${j['status'] ?? 'unpaid'}');
    final deadline = j['deadline'] == null
        ? DateTime.now().add(const Duration(days: 1))
        : DateTime.parse('${j['deadline']}').toLocal();
    return Payment(
      id: '${j['id']}',
      bookingId: '${j['bookingId']}',
      bookingCode: '${j['bookingCode'] ?? ''}',
      amount: (j['amount'] as num).toDouble(),
      status: status,
      proofImageUrl: j['proofImageUrl']?.toString(),
      paidAt: j['paidAt'] == null
          ? null
          : DateTime.parse('${j['paidAt']}').toLocal(),
      verifiedAt: j['verifiedAt'] == null
          ? null
          : DateTime.parse('${j['verifiedAt']}').toLocal(),
      rejectionReason: j['rejectionReason']?.toString(),
      deadline: deadline,
    );
  }
}
