import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/presentation/providers/booking_provider.dart';
import '../../../reviews/presentation/providers/review_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsState = ref.watch(myBookingsProvider);
    final Booking? booking = bookingsState.bookings
        .where((b) => b.id == orderId)
        .cast<Booking?>()
        .firstOrNull;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Pesanan tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.orders),
        ),
        title: Text(
          booking.bookingCode,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _statusBgColor(booking.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _statusIcon(booking.status),
                    color: _statusColor(booking.status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.status.label,
                    style: TextStyle(
                      color: _statusColor(booking.status),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Product info
            _SectionCard(
              title: 'Detail Pesanan',
              children: [
                _DetailRow('Produk', booking.productName),
                _DetailRow(
                  'Tanggal Acara',
                  DateFormatter.formatFull(booking.startDate),
                ),
                _DetailRow('Nama Pemesan', booking.customerName),
                _DetailRow('No. HP', booking.customerPhone),
                _DetailRow('Alamat', booking.eventAddress),
                _DetailRow('Tulisan Pita', booking.eventMessage),
                if (booking.notes != null)
                  _DetailRow('Catatan', booking.notes!),
                _DetailRow(
                  'Metode Penyerahan',
                  booking.withDelivery
                      ? 'Antar - Pasang - Jemput Toko'
                      : 'Pick-up Sendiri di Toko',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _SectionCard(
              title: 'Rincian Biaya',
              children: [
                _DetailRow(
                  'Sewa Papan (24 Jam)',
                  CurrencyFormatter.formatIDR(booking.subtotal),
                ),
                _DetailRow(
                  'Pengiriman & Antar-Jemput',
                  booking.withDelivery
                      ? (booking.deliveryFee > 0
                            ? CurrencyFormatter.formatIDR(booking.deliveryFee)
                            : 'Gratis (Termasuk)')
                      : 'Ambil Sendiri (Rp 0)',
                ),
                _DetailRow(
                  'Pemasangan di Venue',
                  booking.withInstallation
                      ? (booking.installationFee > 0
                            ? CurrencyFormatter.formatIDR(
                                booking.installationFee,
                              )
                            : 'Gratis (Termasuk)')
                      : 'Mandiri (Rp 0)',
                ),
                const Divider(color: AppColors.borderLight, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatIDR(booking.total),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            if (booking.status == BookingStatus.completed)
              _BookingReviewEntry(
                bookingId: booking.id,
                productId: booking.productId,
              ),

            // CTAs
            if (booking.status == BookingStatus.pendingPayment) ...[
              AppButton(
                text: 'Edit Rincian Pesanan',
                type: ButtonType.outlined,
                onPressed: () => context.push(
                  '/booking/${booking.productId}',
                  extra: {'booking': booking},
                ),
                width: double.infinity,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                text: 'Bayar Sekarang',
                onPressed: () =>
                    context.push(RouteNames.paymentPath(booking.id)),
                width: double.infinity,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                text: 'Upload Bukti / Konfirmasi WA',
                type: ButtonType.outlined,
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: () =>
                    context.push(RouteNames.paymentProofPath(booking.id)),
                width: double.infinity,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: 'Batalkan Pesanan',
                type: ButtonType.danger,
                onPressed: () => _cancelBooking(context, ref, booking.id),
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusError),
            child: const Text('Batalkan Pesanan'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(myBookingsProvider.notifier).cancelBooking(id);
      if (context.mounted) context.pop();
    }
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingPayment:
        return AppColors.statusError;
      case BookingStatus.confirmed:
        return AppColors.statusSuccess;
      case BookingStatus.processing:
        return AppColors.statusInfo;
      case BookingStatus.ready:
        return AppColors.statusSuccess;
      case BookingStatus.completed:
        return AppColors.textMuted;
      case BookingStatus.cancelled:
        return AppColors.statusError;
      case BookingStatus.expired:
        return AppColors.textMuted;
    }
  }

  Color _statusBgColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingPayment:
      case BookingStatus.cancelled:
        return AppColors.statusErrorBg;
      case BookingStatus.confirmed:
      case BookingStatus.ready:
      case BookingStatus.completed:
        return AppColors.statusSuccessBg;
      case BookingStatus.processing:
        return AppColors.statusInfoBg;
      case BookingStatus.expired:
        return AppColors.surfaceContainerHigh;
    }
  }

  IconData _statusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingPayment:
        return Icons.payment_outlined;
      case BookingStatus.confirmed:
        return Icons.verified_outlined;
      case BookingStatus.processing:
        return Icons.settings_outlined;
      case BookingStatus.ready:
        return Icons.local_florist;
      case BookingStatus.completed:
        return Icons.check_circle_outline;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
      case BookingStatus.expired:
        return Icons.timer_off_outlined;
    }
  }
}

class _BookingReviewEntry extends ConsumerWidget {
  const _BookingReviewEntry({required this.bookingId, required this.productId});
  final String bookingId;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(bookingReviewProvider(bookingId));
    return review.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (existing) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: existing != null
            ? const Text(
                'Terima kasih, ulasan Anda sudah tersimpan.',
                style: TextStyle(
                  color: AppColors.statusSuccess,
                  fontWeight: FontWeight.w600,
                ),
              )
            : AppButton(
                text: 'Beri Rating dan Ulasan',
                type: ButtonType.outlined,
                icon: const Icon(Icons.star_outline, size: 18),
                onPressed: () => _showReviewDialog(context, ref),
                width: double.infinity,
              ),
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context, WidgetRef ref) async {
    var rating = 5;
    final comment = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Bagaimana pengalaman Anda?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setDialogState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFB7791F),
                    ),
                  ),
                ),
              ),
              TextField(
                controller: comment,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Ulasan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) {
      comment.dispose();
      return;
    }
    try {
      await ref
          .read(reviewDataSourceProvider)
          .submit(
            bookingId: bookingId,
            rating: rating,
            comment: comment.text.trim(),
          );
      ref.invalidate(bookingReviewProvider(bookingId));
      ref.invalidate(productReviewsProvider(productId));
      ref.invalidate(adminReviewsProvider);
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terima kasih atas ulasan Anda.')),
        );
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ulasan gagal dikirim: $error')));
    } finally {
      comment.dispose();
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(color: AppColors.borderLight, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
