import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/booking.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic>? extra;

  const BookingConfirmationScreen({super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    final booking = extra?['booking'] as Booking?;
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: const Center(child: Text('Data booking tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Konfirmasi Booking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking code
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF154D39)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Kode Booking',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.bookingCode,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Details card
            _InfoCard(
              title: 'Detail Pesanan',
              items: [
                _InfoItem('Produk', booking.productName),
                _InfoItem(
                  'Tanggal Acara',
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(booking.startDate),
                ),
                _InfoItem('Nama Pemesan', booking.customerName),
                _InfoItem('Nomor HP', booking.customerPhone),
                _InfoItem('Alamat', booking.eventAddress),
                _InfoItem('Tulisan Pita', booking.eventMessage),
                if (booking.notes != null)
                  _InfoItem('Catatan', booking.notes!),
                _InfoItem(
                    'Pengiriman', booking.withDelivery ? 'Ya' : 'Tidak'),
                _InfoItem(
                    'Instalasi', booking.withInstallation ? 'Ya' : 'Tidak'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _InfoCard(
              title: 'Rincian Harga',
              items: [
                _InfoItem('Sewa Papan',
                    CurrencyFormatter.formatIDR(booking.subtotal)),
                if (booking.withDelivery)
                  _InfoItem('Pengiriman',
                      CurrencyFormatter.formatIDR(booking.deliveryFee)),
                if (booking.withInstallation)
                  _InfoItem('Instalasi',
                      CurrencyFormatter.formatIDR(booking.installationFee)),
              ],
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatIDR(booking.total),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Warning
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.statusWarningBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusWarning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.statusWarning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Slot akan dikonfirmasi setelah pembayaran terverifikasi. Batas waktu pembayaran 24 jam.',
                      style: TextStyle(
                        color: AppColors.statusWarning,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: 'Lanjut ke Pembayaran',
              onPressed: () => context.go(
                RouteNames.paymentPath(booking.id),
              ),
              width: double.infinity,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Kembali',
              type: ButtonType.outlined,
              onPressed: () => context.pop(),
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;
  final Widget? footer;

  const _InfoCard({required this.title, required this.items, this.footer});

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
            child: Column(
              children: [
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.value,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (footer != null) ...[
                  const Divider(color: AppColors.borderLight),
                  footer!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}
