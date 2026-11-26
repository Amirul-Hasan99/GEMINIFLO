import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/widgets/empty_widget.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/admin_bottom_nav.dart';
import '../../../../booking/domain/entities/booking.dart';
import '../../../../booking/presentation/providers/booking_provider.dart';
import '../../../../payment/domain/entities/payment.dart';
import '../../../../payment/presentation/providers/payment_provider.dart';

class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsState = ref.watch(adminPaymentsListProvider);
    final bookingsState = ref.watch(myBookingsProvider);
    final notifier = ref.read(adminPaymentsListProvider.notifier);

    final currentFilter = paymentsState.filterStatus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.adminDashboard),
        ),
        title: const Text(
          'Kelola Booking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: AppColors.surfaceWhite,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    isSelected: currentFilter == null,
                    onTap: () => notifier.setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Menunggu Verifikasi',
                    isSelected:
                        currentFilter == PaymentStatus.waitingVerification,
                    badgeCount: paymentsState.payments
                        .where(
                          (p) => p.status == PaymentStatus.waitingVerification,
                        )
                        .length,
                    onTap: () =>
                        notifier.setFilter(PaymentStatus.waitingVerification),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Terverifikasi',
                    isSelected: currentFilter == PaymentStatus.verified,
                    onTap: () => notifier.setFilter(PaymentStatus.verified),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Ditolak',
                    isSelected: currentFilter == PaymentStatus.rejected,
                    onTap: () => notifier.setFilter(PaymentStatus.rejected),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Payments list
          Expanded(
            child: paymentsState.isLoading
                ? const LoadingWidget()
                : paymentsState.payments.isEmpty
                ? RefreshIndicator(
                    onRefresh: () => notifier.loadPayments(),
                    color: AppColors.primary,
                    child: ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyWidget(
                          message: 'Belum Ada Bukti Pembayaran',
                          subMessage: 'Bukti transfer dari pelanggan akan muncul di sini',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => notifier.loadPayments(),
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: paymentsState.payments.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final payment = paymentsState.payments[i];
                        final booking = bookingsState.bookings
                            .where((b) => b.id == payment.bookingId)
                            .cast<Booking?>()
                            .firstOrNull;

                        return _AdminPaymentCard(
                          payment: payment,
                          booking: booking,
                          onTap: () => context.push(
                            RouteNames.adminPaymentDetailPath(payment.id),
                          ),
                          onDelete: () => _confirmDelete(context, ref, payment),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Payment payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Riwayat Pembayaran?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus riwayat pembayaran ${payment.bookingCode}? Data ini akan dihapus dari riwayat transaksi sistem.',
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
              final success = await ref
                  .read(adminPaymentsListProvider.notifier)
                  .deletePayment(payment.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Riwayat pembayaran ${payment.bookingCode} berhasil dihapus'
                          : 'Gagal menghapus pembayaran',
                    ),
                    backgroundColor: success
                        ? AppColors.statusSuccess
                        : AppColors.statusError,
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.statusError,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminPaymentCard extends StatelessWidget {
  final Payment payment;
  final Booking? booking;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AdminPaymentCard({
    required this.payment,
    required this.booking,
    required this.onTap,
    required this.onDelete,
  });

  Color _statusColor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.unpaid:
        return AppColors.statusError;
      case PaymentStatus.waitingVerification:
        return AppColors.statusWarning;
      case PaymentStatus.verified:
        return AppColors.statusSuccess;
      case PaymentStatus.rejected:
        return AppColors.statusError;
      case PaymentStatus.expired:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = booking?.customerName ?? 'Pelanggan';
    final product = booking?.productName ?? 'Papan Bunga Geminiflo';
    final deliveryText = (booking?.withDelivery ?? true)
        ? 'Antar-Jemput Toko & Instalasi'
        : 'Pick-up Sendiri di Toko';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: payment.status == PaymentStatus.waitingVerification
                ? AppColors.statusWarning.withValues(alpha: 0.5)
                : AppColors.borderLight,
            width: payment.status == PaymentStatus.waitingVerification
                ? 1.5
                : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  payment.bookingCode,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(payment.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    payment.status.label,
                    style: TextStyle(
                      color: _statusColor(payment.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    color: AppColors.statusError,
                    size: 16,
                  ),
                  tooltip: 'Hapus Riwayat Pembayaran',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              customer,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              product,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  LucideIcons.truck,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    deliveryText,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.borderLight),
            Row(
              children: [
                if (payment.paidAt != null) ...[
                  const Icon(
                    LucideIcons.clock,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatShort(payment.paidAt!),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  CurrencyFormatter.formatIDR(payment.amount),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
