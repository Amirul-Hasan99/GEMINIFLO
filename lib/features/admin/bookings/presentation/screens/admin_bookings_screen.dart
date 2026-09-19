import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/currency_formatter.dart';
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
        title: const Text(
          'Kelola Booking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                      );
                    },
                  ),
                ),
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _AdminBookingCard({required this.booking, required this.onTap});

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
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(booking.status)
                        .withValues(alpha: 0.12),
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
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormat('d MMM yyyy', 'id_ID').format(booking.startDate),
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
