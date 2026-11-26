import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import '../../../../catalog/presentation/providers/catalog_provider.dart';
import '../../utils/reports_exporter.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedFilter =
      'all'; // 'all', 'confirmed', 'pendingPayment', 'cancelled'
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(myBookingsProvider);
    final catalogState = ref.watch(catalogProvider);

    if (bookingsState.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, [], 0, {}),
        bottomNavigationBar: const AdminBottomNav(currentIndex: 4),
        body: const LoadingWidget(),
      );
    }

    final allBookings = bookingsState.bookings;

    // Filtered bookings according to active filter
    final filteredBookings = allBookings.where((b) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'confirmed') {
        return b.status == BookingStatus.confirmed;
      }
      if (_selectedFilter == 'pendingPayment') {
        return b.status == BookingStatus.pendingPayment;
      }
      if (_selectedFilter == 'cancelled') {
        return b.status == BookingStatus.cancelled;
      }
      return true;
    }).toList();

    // 100% REAL dynamic metrics computed from actual bookings
    final totalOmzet = filteredBookings.fold<double>(
      0.0,
      (sum, b) => b.status != BookingStatus.cancelled ? sum + b.total : sum,
    );

    final totalOrders = filteredBookings.length;
    final averageOrderValue = totalOrders == 0 ? 0.0 : totalOmzet / totalOrders;

    // Real dynamic monthly data for the past 6 months
    final now = DateTime.now();
    final monthlyData = <Map<String, dynamic>>[];
    double maxMonthlyAmount = 100000.0;

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthName = DateFormat('MMM', 'id_ID').format(monthDate);
      final monthYear = monthDate.year;
      final monthNum = monthDate.month;

      final monthOrders = filteredBookings.where((b) {
        return b.createdAt.year == monthYear && b.createdAt.month == monthNum;
      }).toList();

      final monthAmount = monthOrders.fold<double>(
        0.0,
        (sum, b) => b.status != BookingStatus.cancelled ? sum + b.total : sum,
      );

      if (monthAmount > maxMonthlyAmount) {
        maxMonthlyAmount = monthAmount;
      }

      monthlyData.add({
        'month': monthName,
        'amount': monthAmount,
        'orders': monthOrders.length,
      });
    }

    // Real dynamic category breakdown
    final categoryCounts = <String, int>{};
    for (final b in filteredBookings) {
      String cat = 'Lainnya';
      final matchingProduct = catalogState.products
          .where((p) => p.id == b.productId)
          .cast<dynamic>()
          .firstOrNull;

      if (matchingProduct != null) {
        cat = matchingProduct.categoryName;
      } else {
        // Fallback inferred from product name
        final nameLower = b.productName.toLowerCase();
        if (nameLower.contains('wedding') ||
            nameLower.contains('nikah') ||
            nameLower.contains('peony')) {
          cat = 'Pernikahan';
        } else if (nameLower.contains('opening') ||
            nameLower.contains('sukses')) {
          cat = 'Grand Opening';
        } else if (nameLower.contains('wisuda')) {
          cat = 'Wisuda';
        } else if (nameLower.contains('duka')) {
          cat = 'Duka Cita';
        } else if (nameLower.contains('ulang tahun') ||
            nameLower.contains('ceria')) {
          cat = 'Ulang Tahun';
        }
      }

      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    final categoryColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.statusInfo,
      AppColors.statusWarning,
      const Color(0xFF8E44AD),
      AppColors.textMuted,
    ];

    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(
        context,
        filteredBookings,
        totalOmzet,
        categoryCounts,
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 4),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua (${allBookings.length})',
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Terkonfirmasi',
                    isSelected: _selectedFilter == 'confirmed',
                    onTap: () => setState(() => _selectedFilter = 'confirmed'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Menunggu Bayar',
                    isSelected: _selectedFilter == 'pendingPayment',
                    onTap: () =>
                        setState(() => _selectedFilter = 'pendingPayment'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'Dibatalkan',
                    isSelected: _selectedFilter == 'cancelled',
                    onTap: () => setState(() => _selectedFilter = 'cancelled'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _ReportMetricCard(
                    label: 'Omzet Bersih',
                    value: CurrencyFormatter.formatIDR(totalOmzet),
                    icon: LucideIcons.trendingUp,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportMetricCard(
                    label: 'Pesanan',
                    value: '$totalOrders',
                    icon: LucideIcons.receipt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportMetricCard(
                    label: 'Rata-rata',
                    value: CurrencyFormatter.formatIDR(averageOrderValue),
                    icon: LucideIcons.wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 150,
              child: _MonthlyRevenuePanel(
                data: monthlyData,
                maxAmount: maxMonthlyAmount,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: sortedCategories.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Belum ada data kategori',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sortedCategories.take(6).length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final entry = sortedCategories[index];
                        final color =
                            categoryColors[index % categoryColors.length];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: color.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Text(
                            '${entry.key} · ${entry.value}',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Transaksi terbaru',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${filteredBookings.length} data',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            Expanded(
              child: filteredBookings.isEmpty
                  ? const Center(
                      child: EmptyWidget(
                        message: 'Belum Ada Transaksi',
                        subMessage: 'Pesanan sesuai filter akan muncul di sini',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(myBookingsProvider.notifier).loadBookings(),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 6, bottom: 4),
                        itemCount: filteredBookings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) =>
                            _CompactReportRow(booking: filteredBookings[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    List<Booking> bookings,
    double totalOmzet,
    Map<String, int> categories,
  ) {
    return AppBar(
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
        'Laporan & Analitik',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.fileText, size: 20),
          tooltip: 'Cetak / Ekspor PDF',
          onPressed: _isExporting
              ? null
              : () => _handleExportPdf(bookings, totalOmzet, categories),
        ),
        IconButton(
          icon: const Icon(LucideIcons.fileSpreadsheet, size: 20),
          tooltip: 'Unduh Excel (CSV)',
          onPressed: _isExporting
              ? null
              : () => _handleExportExcel(bookings, totalOmzet),
        ),
      ],
    );
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'confirmed':
        return 'Terkonfirmasi';
      case 'pendingPayment':
        return 'Menunggu Bayar';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Semua Orderan';
    }
  }

  Future<void> _handleExportPdf(
    List<Booking> bookings,
    double totalOmzet,
    Map<String, int> categories,
  ) async {
    setState(() => _isExporting = true);
    try {
      await ReportsExporter.exportToPdf(
        bookings: bookings,
        totalOmzet: totalOmzet,
        categoryCounts: categories,
        filterTitle: _getFilterLabel(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor PDF: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleExportExcel(
    List<Booking> bookings,
    double totalOmzet,
  ) async {
    setState(() => _isExporting = true);
    try {
      final fileName = await ReportsExporter.exportToExcelCsv(
        bookings: bookings,
        totalOmzet: totalOmzet,
        filterTitle: _getFilterLabel(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fileName == null
                  ? 'Gagal mengunduh file Excel. Silakan coba lagi.'
                  : 'File Excel (CSV) berhasil diunduh atau dibagikan.',
            ),
            backgroundColor: fileName == null
                ? AppColors.statusError
                : AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh file Excel: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _ReportMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _ReportMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: highlight ? AppColors.primary : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: highlight ? AppColors.primary : AppColors.borderLight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          icon,
          size: 15,
          color: highlight ? AppColors.secondary : AppColors.primary,
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9.5,
            color: highlight ? Colors.white70 : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: highlight ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

class _MonthlyRevenuePanel extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double maxAmount;

  const _MonthlyRevenuePanel({required this.data, required this.maxAmount});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
    decoration: BoxDecoration(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pendapatan 6 Bulan Terakhir',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final amount = (item['amount'] as num).toDouble();
              final ratio = maxAmount <= 0
                  ? 0.08
                  : (amount / maxAmount).clamp(0.08, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        amount == 0 ? '0' : '${(amount / 1000).round()}k',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 58 * ratio,
                        decoration: BoxDecoration(
                          color: amount == 0
                              ? AppColors.surfaceContainerHigh
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['month'] as String,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

class _CompactReportRow extends StatelessWidget {
  final Booking booking;

  const _CompactReportRow({required this.booking});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.background,
          child: Icon(LucideIcons.receipt, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.bookingCode,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${booking.customerName} · ${booking.productName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                DateFormatter.formatShort(booking.startDate),
                maxLines: 1,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          CurrencyFormatter.formatIDR(booking.total),
          maxLines: 1,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
