import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/product_image.dart';
import '../../../../booking/domain/entities/booking.dart';
import '../../../../booking/presentation/providers/booking_provider.dart';
import '../../../../payment/domain/entities/payment.dart';
import '../../../../payment/presentation/providers/payment_provider.dart';

class AdminPaymentDetailScreen extends ConsumerStatefulWidget {
  final String paymentId;

  const AdminPaymentDetailScreen({super.key, required this.paymentId});

  @override
  ConsumerState<AdminPaymentDetailScreen> createState() =>
      _AdminPaymentDetailScreenState();
}

class _AdminPaymentDetailScreenState
    extends ConsumerState<AdminPaymentDetailScreen> {
  bool _isProcessing = false;

  Future<void> _handleVerify(Payment payment) async {
    setState(() => _isProcessing = true);
    final success = await ref
        .read(adminPaymentsListProvider.notifier)
        .verifyPayment(payment.id, true);
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pembayaran berhasil diverifikasi! Status booking: CONFIRMED',
          ),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
    }
  }

  void _confirmDeletePayment(Payment payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Riwayat Pembayaran?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data riwayat pembayaran untuk ${payment.bookingCode}? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);
              final success = await ref
                  .read(adminPaymentsListProvider.notifier)
                  .deletePayment(payment.id);
              if (!mounted) return;
              setState(() => _isProcessing = false);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Riwayat pembayaran ${payment.bookingCode} berhasil dihapus',
                    ),
                    backgroundColor: AppColors.statusSuccess,
                  ),
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.adminPayments);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus riwayat pembayaran'),
                    backgroundColor: AppColors.statusError,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Payment payment) {
    String selectedReason = 'Nominal transfer tidak sesuai tagihan';
    final reasons = [
      'Nominal transfer tidak sesuai tagihan',
      'Bukti transfer buram atau tidak terbaca',
      'Rekening tujuan bukan milik Geminiflo',
      'Mutasi rekening belum masuk',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tolak Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusError,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih alasan penolakan bukti bayar untuk pesanan ${payment.bookingCode}:',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...reasons.map(
                // ignore: deprecated_member_use
                (reason) => RadioListTile<String>(
                  value: reason,
                  // ignore: deprecated_member_use
                  groupValue: selectedReason,
                  title: Text(reason, style: const TextStyle(fontSize: 13)),
                  activeColor: AppColors.statusError,
                  contentPadding: EdgeInsets.zero,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    if (val != null) {
                      setSheetState(() => selectedReason = val);
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: 'Konfirmasi Penolakan',
                type: ButtonType.danger,
                width: double.infinity,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  setState(() => _isProcessing = true);
                  final success = await ref
                      .read(adminPaymentsListProvider.notifier)
                      .verifyPayment(payment.id, false, reason: selectedReason);
                  if (!mounted) return;
                  setState(() => _isProcessing = false);

                  if (success) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Pembayaran ditolak: $selectedReason'),
                        backgroundColor: AppColors.statusError,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chatCustomerViaWhatsApp(
    Booking? booking,
    Payment payment,
  ) async {
    final phone = (booking?.customerPhone ?? '').replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final intlPhone = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;

    final customerName = booking?.customerName ?? 'Kak';
    final isVerified = payment.status == PaymentStatus.verified;
    final isRejected = payment.status == PaymentStatus.rejected;

    String text;
    if (isVerified) {
      text =
          'Halo $customerName, pembayaran untuk pesanan papan bunga ${payment.bookingCode} telah terverifikasi. Pesanan Anda akan segera diproses. Terima kasih!';
    } else if (isRejected) {
      text =
          'Halo $customerName, bukti transfer untuk pesanan ${payment.bookingCode} tidak dapat kami verifikasi karena: ${payment.rejectionReason ?? "data tidak sesuai"}. Mohon kirimkan ulang bukti yang valid. Terima kasih.';
    } else {
      text =
          'Halo $customerName, kami dari Admin Geminiflo ingin konfirmasi terkait pembayaran pesanan ${payment.bookingCode}.';
    }

    final uri = Uri.parse(
      'https://wa.me/$intlPhone?text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(adminPaymentsListProvider);
    final bookingsState = ref.watch(myBookingsProvider);

    final Payment? payment = paymentsState.payments
        .where(
          (p) => p.id == widget.paymentId || p.bookingId == widget.paymentId,
        )
        .cast<Payment?>()
        .firstOrNull;

    if (payment == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Detail Booking'),
        ),
        body: const Center(child: Text('Data pembayaran tidak ditemukan')),
      );
    }

    final booking = bookingsState.bookings
        .where((b) => b.id == payment.bookingId)
        .cast<Booking?>()
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.adminPayments),
        ),
        title: Text(
          payment.bookingCode,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Hapus Riwayat Pembayaran',
            onPressed: _isProcessing
                ? null
                : () => _confirmDeletePayment(payment),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            _StatusBanner(status: payment.status),
            const SizedBox(height: AppSpacing.lg),

            // Amount summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  const Text(
                    'Nominal yang Harus Dibayar',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.formatIDR(payment.amount),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (payment.paidAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Diunggah: ${DateFormatter.formatFull(payment.paidAt!)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (payment.rejectionReason != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusErrorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Alasan Ditolak: ${payment.rejectionReason}',
                        style: const TextStyle(
                          color: AppColors.statusError,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Customer details
            if (booking != null) ...[
              _InfoSection(
                title: 'Data Pelanggan & Penerima',
                children: [
                  _InfoRow('Nama', booking.customerName),
                  _InfoRow('Nomor HP', booking.customerPhone),
                  _InfoRow('Alamat Lokasi', booking.eventAddress),
                  _InfoRow('Pesan di Pita', booking.eventMessage),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _InfoSection(
                title: 'Rincian Pesanan Papan Bunga',
                children: [
                  _InfoRow('Produk', booking.productName),
                  _InfoRow(
                    'Tanggal Acara',
                    DateFormatter.formatFull(booking.startDate),
                  ),
                  _InfoRow(
                    'Pengiriman',
                    booking.withDelivery
                        ? 'Antar-Jemput Toko & Instalasi (Include)'
                        : 'Pick-up Sendiri di Toko',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Proof of payment inspector
            _InfoSection(
              title: 'Inspeksi Bukti Bayar',
              children: [
                if (payment.proofImageUrl != null &&
                    payment.proofImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: ProductImage(
                        source: payment.proofImageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: AppColors.primary,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada gambar bukti yang diunggah di aplikasi.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bukti transfer tersimpan di database dan dapat diperiksa pada halaman ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action buttons
            if (payment.status == PaymentStatus.waitingVerification) ...[
              AppButton(
                text: 'Verifikasi & Terima Pembayaran',
                onPressed: _isProcessing ? null : () => _handleVerify(payment),
                isLoading: _isProcessing,
                width: double.infinity,
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                text: 'Tolak Pembayaran',
                type: ButtonType.danger,
                onPressed: _isProcessing
                    ? null
                    : () => _showRejectDialog(payment),
                width: double.infinity,
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.statusError,
                  size: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Direct WhatsApp Chat with Customer
            AppButton(
              text: 'Chat Pelanggan via WhatsApp',
              type: ButtonType.outlined,
              onPressed: () => _chatCustomerViaWhatsApp(booking, payment),
              width: double.infinity,
              icon: const Icon(
                Icons.chat_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Hapus Riwayat Pembayaran',
              type: ButtonType.danger,
              onPressed: _isProcessing
                  ? null
                  : () => _confirmDeletePayment(payment),
              width: double.infinity,
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.statusError,
                size: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final PaymentStatus status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceContainerHigh;
    Color fg = AppColors.textMuted;
    IconData icon = Icons.info_outline;

    switch (status) {
      case PaymentStatus.unpaid:
        bg = AppColors.statusErrorBg;
        fg = AppColors.statusError;
        icon = Icons.error_outline;
        break;
      case PaymentStatus.waitingVerification:
        bg = AppColors.statusWarningBg;
        fg = AppColors.statusWarning;
        icon = Icons.hourglass_empty;
        break;
      case PaymentStatus.verified:
        bg = AppColors.statusSuccessBg;
        fg = AppColors.statusSuccess;
        icon = Icons.verified;
        break;
      case PaymentStatus.rejected:
        bg = AppColors.statusErrorBg;
        fg = AppColors.statusError;
        icon = Icons.cancel;
        break;
      case PaymentStatus.expired:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.textMuted;
        icon = Icons.timer_off;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
