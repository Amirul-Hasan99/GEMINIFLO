enum PaymentStatus {
  unpaid,
  waitingVerification,
  verified,
  rejected,
  expired;

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Belum Bayar';
      case PaymentStatus.waitingVerification:
        return 'Menunggu Verifikasi';
      case PaymentStatus.verified:
        return 'Terverifikasi';
      case PaymentStatus.rejected:
        return 'Ditolak';
      case PaymentStatus.expired:
        return 'Kadaluarsa';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'waiting_verification':
        return PaymentStatus.waitingVerification;
      case 'verified':
        return PaymentStatus.verified;
      case 'rejected':
        return PaymentStatus.rejected;
      case 'expired':
        return PaymentStatus.expired;
      default:
        return PaymentStatus.unpaid;
    }
  }
}

class Payment {
  final String id;
  final String bookingId;
  final String bookingCode;
  final double amount;
  final PaymentStatus status;
  final String? proofImageUrl;
  final DateTime? paidAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final DateTime deadline;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.bookingCode,
    required this.amount,
    required this.status,
    this.proofImageUrl,
    this.paidAt,
    this.verifiedAt,
    this.rejectionReason,
    required this.deadline,
  });
}

class PaymentMethod {
  final String id;
  final String type; // 'bank_transfer' | 'ewallet' | 'qris'
  final String name;
  final String? accountNumber;
  final String? accountName;
  final String? bankCode;
  final String? logoUrl;
  final bool isActive;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    this.accountNumber,
    this.accountName,
    this.bankCode,
    this.logoUrl,
    required this.isActive,
  });
}
