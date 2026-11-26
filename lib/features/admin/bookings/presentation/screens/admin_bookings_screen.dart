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
import '../../../../../features/booking/domain/entities/booking.dart';
import '../../../../../features/booking/presentation/providers/booking_provider.dart';

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsState = ref.watch(myBookingsProvider);

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
      body: bookingsState.isLoading
          ? const LoadingWidget()
          : bookingsState.bookings.isEmpty
          ? const EmptyWidget(
              message: 'Belum Ada Booking',
              subMessage: 'Booking pelanggan akan muncul di sini',
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(myBookingsProvider.notifier).loadBookings(),
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: bookingsState.bookings.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final booking = bookingsState.bookings[i];
                  return _AdminBookingCard(
                    booking: booking,
                    onTap: () => context.push(
                      RouteNames.adminBookingDetailPath(booking.id),
                    ),
                    onDelete: _isHistoryBooking(booking.status)
                        ? () => _confirmDelete(context, ref, booking)
                        : null,
                  );
                },
              ),
            ),
    );
  }

  bool _isHistoryBooking(BookingStatus status) =>
      status == BookingStatus.completed ||
      status == BookingStatus.cancelled ||
      status == BookingStatus.expired;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus riwayat booking?'),
        content: Text(
          'Riwayat ${booking.bookingCode} akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await ref.read(myBookingsProvider.notifier).deleteBooking(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Riwayat ${booking.bookingCode} berhasil dihapus.'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus riwayat booking: $error'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }
}

class _AdminBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _AdminBookingCard({
    required this.booking,
    required this.onTap,
    this.onDelete,
  });

  Color _statusColor(BookingStatus s) {
    switch (s) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  booking.bookingCode,
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
                    color: _statusColor(booking.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    booking.status.label,
                    style: TextStyle(
                      color: _statusColor(booking.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Hapus riwayat booking',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    onPressed: onDelete,
                    icon: const Icon(
                      LucideIcons.trash2,
                      size: 17,
                      color: AppColors.statusError,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              booking.customerName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (booking.customerEmail?.isNotEmpty == true ||
                booking.customerUsername?.isNotEmpty == true)
              Text(
                [
                  if (booking.customerUsername?.isNotEmpty == true)
                    '@${booking.customerUsername}',
                  if (booking.customerEmail?.isNotEmpty == true)
                    booking.customerEmail!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            Text(
              booking.productName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.formatShort(booking.startDate),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  CurrencyFormatter.formatIDR(booking.total),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
