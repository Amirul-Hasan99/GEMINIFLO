import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/presentation/providers/booking_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    'Semua',
    'Menunggu',
    'Diproses',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: bookingsState.isLoading
          ? const LoadingWidget()
          : bookingsState.bookings.isEmpty
              ? const EmptyWidget(
                  message: 'Belum Ada Pesanan',
                  subMessage:
                      'Mulai booking papan bunga pertama Anda sekarang',
                  icon: Icons.receipt_long_outlined,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _BookingList(bookings: bookingsState.bookings),
                    _BookingList(
                      bookings: bookingsState.bookings
                          .where((b) =>
                              b.status == BookingStatus.pendingPayment)
                          .toList(),
                    ),
                    _BookingList(
                      bookings: bookingsState.bookings
                          .where((b) =>
                              b.status == BookingStatus.confirmed ||
                              b.status == BookingStatus.processing ||
                              b.status == BookingStatus.ready)
                          .toList(),
                    ),
                    _BookingList(
                      bookings: bookingsState.bookings
                          .where(
                              (b) => b.status == BookingStatus.completed)
                          .toList(),
                    ),
                    _BookingList(
                      bookings: bookingsState.bookings
                          .where((b) =>
                              b.status == BookingStatus.cancelled ||
                              b.status == BookingStatus.expired)
                          .toList(),
                    ),
                  ],
                ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go(RouteNames.home);
              break;
            case 1:
              context.go(RouteNames.catalog);
              break;
            case 3:
              context.go(RouteNames.profile);
              break;
          }
        },
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;

  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const EmptyWidget(
        message: 'Tidak ada pesanan',
        subMessage: '',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => _OrderCard(booking: bookings[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Booking booking;

  const _OrderCard({required this.booking});

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push(RouteNames.orderDetailPath(booking.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
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
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(booking.status)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
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
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.productName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatShort(booking.startDate),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.formatIDR(booking.total),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (booking.status == BookingStatus.pendingPayment) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => context.push(
                          RouteNames.paymentPath(booking.id),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusError,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Bayar Sekarang',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
