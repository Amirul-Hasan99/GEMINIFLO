import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/app_logo.dart';
import '../../../../../core/widgets/admin_bottom_nav.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/booking/domain/entities/booking.dart';
import '../../../../../features/booking/presentation/providers/booking_provider.dart';
import '../../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../payment/domain/entities/payment.dart';
import '../../../../payment/presentation/providers/payment_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final bookings = ref.watch(myBookingsProvider);
    final paymentsState = ref.watch(adminPaymentsListProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final pendingPayments = paymentsState.payments
        .where((p) => p.status == PaymentStatus.waitingVerification)
        .length;

    final allBookings = bookings.bookings;
    final confirmedUnits = allBookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;

    // Real Omzet: only non-cancelled bookings
    final realOmzet = allBookings
        .where((b) => b.status != BookingStatus.cancelled)
        .fold(0.0, (sum, b) => sum + b.total);

    final recentBookings = allBookings.take(3).toList();
    final today = DateTime.now();
    final chartDays = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day - 6 + index),
    );
    final weeklyBookingCounts = chartDays
        .map(
          (day) => allBookings.where((booking) {
            final createdAt = booking.createdAt.toLocal();
            return createdAt.year == day.year &&
                createdAt.month == day.month &&
                createdAt.day == day.day;
          }).length,
        )
        .toList();
    final chartLabels = chartDays
        .map((day) => DateFormat('dd/MM').format(day))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleSpacing: 14,
        title: Row(
          children: [
            const AppHeaderLogo(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Admin Panel',
                    style: TextStyle(fontSize: 11, color: AppColors.secondary),
                  ),
                  Text(
                    auth.user?.name ?? 'Admin',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifikasi',
                onPressed: () => context.push(RouteNames.notifications),
                icon: const Icon(LucideIcons.bell, size: 20),
              ),
              if (unreadCount > 0)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.secondary,
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Pengaturan toko',
            onPressed: () => context.push(RouteNames.adminSettings),
            icon: const Icon(LucideIcons.settings, size: 19),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(LucideIcons.logOut, size: 19),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeeklyBookingsChart(
                values: weeklyBookingCounts,
                labels: chartLabels,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ringkasan Operasional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Data terkini',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720 ? 4 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: columns == 4 ? 2.15 : 1.75,
                    children: [
                      _ShadcnStatCard(
                        label: 'Bukti Masuk',
                        value: '$pendingPayments',
                        icon: LucideIcons.clock,
                        hasBadge: pendingPayments > 0,
                      ),
                      _ShadcnStatCard(
                        label: 'Total Pesanan',
                        value: '${allBookings.length}',
                        icon: LucideIcons.package,
                      ),
                      _ShadcnStatCard(
                        label: 'Terkonfirmasi',
                        value: '$confirmedUnits',
                        icon: LucideIcons.checkCircle2,
                      ),
                      _ShadcnStatCard(
                        label: 'Omzet Riil',
                        value: CurrencyFormatter.formatIDR(realOmzet),
                        icon: LucideIcons.trendingUp,
                        isLargeValue: true,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pesanan Terbaru',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go(RouteNames.adminPayments),
                    icon: const Icon(LucideIcons.arrowRight, size: 14),
                    label: const Text(
                      'Lihat semua',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: recentBookings.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada pesanan terbaru',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: recentBookings.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: AppColors.borderLight,
                          ),
                          itemBuilder: (context, i) {
                            final booking = recentBookings[i];
                            return ListTile(
                              dense: true,
                              leading: const CircleAvatar(
                                radius: 17,
                                backgroundColor: AppColors.background,
                                child: Icon(
                                  LucideIcons.package,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                booking.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${booking.customerName} · ${booking.bookingCode}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10.5),
                              ),
                              trailing: const Icon(
                                LucideIcons.chevronRight,
                                size: 17,
                                color: AppColors.textMuted,
                              ),
                              onTap: () => context.go(RouteNames.adminPayments),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }
}

class _WeeklyBookingsChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;

  const _WeeklyBookingsChart({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Booking 7 Hari Terakhir',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'PER HARI',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Jumlah pesanan berdasarkan tanggal dibuat',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _BookingsBarChartPainter(values: values),
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 27),
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingsBarChartPainter extends CustomPainter {
  final List<int> values;

  const _BookingsBarChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const left = 24.0;
    const right = 8.0;
    const top = 14.0;
    const bottom = 6.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final maxValue = values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    final scaleMax = maxValue == 0 ? 1 : maxValue;
    final gridPaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1;
    final barPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    for (var tick = 0; tick <= 3; tick++) {
      final y = top + chartHeight - chartHeight * tick / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      final tickValue = (scaleMax * tick / 3).round();
      _drawLabel(
        canvas,
        '$tickValue',
        Offset(0, y - 6),
        const TextStyle(color: AppColors.textMuted, fontSize: 8),
        width: left - 5,
        align: TextAlign.right,
      );
    }

    final slotWidth = chartWidth / values.length;
    final barWidth = (slotWidth * 0.52).clamp(5.0, 22.0);
    for (var index = 0; index < values.length; index++) {
      final barHeight = chartHeight * values[index] / scaleMax;
      final centerX = left + slotWidth * (index + 0.5);
      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        top + chartHeight - barHeight,
        barWidth,
        barHeight,
      );
      if (values[index] > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          barPaint,
        );
        _drawLabel(
          canvas,
          '${values[index]}',
          Offset(centerX - slotWidth / 2, rect.top - 13),
          const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
          width: slotWidth,
          align: TextAlign.center,
        );
      }
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double width,
    required TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BookingsBarChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _ShadcnStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool hasBadge;
  final bool isLargeValue;

  const _ShadcnStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.hasBadge = false,
    this.isLargeValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Icon(icon, color: const Color(0xFF09090B), size: 16),
              ),
              if (hasBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09090B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Perlu Cek',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF09090B),
              fontSize: isLargeValue ? 15 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF71717A),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
