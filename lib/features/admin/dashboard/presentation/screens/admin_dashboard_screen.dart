import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/booking/presentation/providers/booking_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final bookings = ref.watch(myBookingsProvider);

    final pendingPayments = bookings.bookings
        .where((b) =>
            b.status.name == 'pendingPayment')
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A2B1F), Color(0xFF0F382A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + AppSpacing.md,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.secondary, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            auth.user?.name.isNotEmpty == true
                                ? auth.user!.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Panel',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            auth.user?.name ?? 'Admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_outlined,
                            color: Colors.white),
                        onPressed: () =>
                            ref.read(authStateProvider.notifier).logout(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Stats cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Hari Ini',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(
                        label: 'Bukti Baru',
                        value: '$pendingPayments',
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.statusError,
                        hasBadge: pendingPayments > 0,
                      ),
                      _StatCard(
                        label: 'Pesanan Baru',
                        value: '${bookings.bookings.length}',
                        icon: Icons.shopping_bag_outlined,
                        color: AppColors.statusInfo,
                      ),
                      _StatCard(
                        label: 'Unit Terpasang',
                        value: '3',
                        icon: Icons.local_florist,
                        color: AppColors.statusSuccess,
                      ),
                      _StatCard(
                        label: 'Omzet Berjalan',
                        value: CurrencyFormatter.formatIDR(
                          bookings.bookings.fold(
                              0.0, (sum, b) => sum + b.total),
                        ),
                        icon: Icons.trending_up_outlined,
                        color: AppColors.secondary,
                        isLargeValue: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aksi Cepat',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _AdminQuickAction(
                    icon: Icons.inventory_2_outlined,
                    label: 'Kelola Produk',
                    subtitle: 'Tambah, edit, hapus papan bunga',
                    onTap: () => context.push(RouteNames.adminProducts),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AdminQuickAction(
                    icon: Icons.receipt_long_outlined,
                    label: 'Kelola Booking',
                    subtitle: 'Verifikasi dan proses pesanan',
                    onTap: () => context.push(RouteNames.adminBookings),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AdminQuickAction(
                    icon: Icons.payment_outlined,
                    label: 'Verifikasi Pembayaran',
                    subtitle: 'Proses bukti pembayaran masuk',
                    badge: pendingPayments,
                    onTap: () => context.push(RouteNames.adminPayments),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AdminQuickAction(
                    icon: Icons.bar_chart_outlined,
                    label: 'Laporan',
                    subtitle: 'Statistik dan analitik bisnis',
                    onTap: () => context.push(RouteNames.adminReports),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AdminQuickAction(
                    icon: Icons.settings_outlined,
                    label: 'Pengaturan Bisnis',
                    subtitle: 'Rekening, jam operasional, dll.',
                    onTap: () => context.push(RouteNames.adminSettings),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool hasBadge;
  final bool isLargeValue;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.hasBadge = false,
    this.isLargeValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (hasBadge) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.statusError,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isLargeValue ? 14 : 24,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  const _AdminQuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusError,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
