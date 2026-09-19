import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../features/booking/domain/entities/booking.dart';
import '../../../../../features/booking/presentation/providers/booking_provider.dart';

class AdminBookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const AdminBookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsState = ref.watch(myBookingsProvider);
    final Booking? booking = bookingsState.bookings
        .where((b) => b.id == bookingId)
        .cast<Booking?>()
        .firstOrNull;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: const Center(child: Text('Booking tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(booking.bookingCode,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.statusInfoBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                booking.status.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.statusInfo,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Section(
              title: 'Pelanggan',
              children: [
                _Row('Nama', booking.customerName),
                _Row('HP', booking.customerPhone),
                _Row('Alamat', booking.eventAddress),
                _Row('Pita', booking.eventMessage),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: 'Pesanan',
              children: [
                _Row('Produk', booking.productName),
                _Row(
                    'Tanggal',
                    DateFormat('d MMMM yyyy', 'id_ID')
                        .format(booking.startDate)),
                _Row('Pengiriman', booking.withDelivery ? 'Ya' : 'Tidak'),
                _Row('Instalasi', booking.withInstallation ? 'Ya' : 'Tidak'),
                const Divider(color: AppColors.borderLight, height: 16),
                _Row('Total',
                    CurrencyFormatter.formatIDR(booking.total),
                    isBold: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Admin actions
            AppButton(
              text: 'Konfirmasi Booking',
              onPressed: booking.status == BookingStatus.pendingPayment
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Booking dikonfirmasi'),
                            backgroundColor: AppColors.statusSuccess),
                      );
                    }
                  : null,
              width: double.infinity,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Chat via WhatsApp',
              type: ButtonType.outlined,
              icon: const Icon(Icons.chat_outlined,
                  size: 18, color: AppColors.primary),
              onPressed: () async {
                final phone = booking.customerPhone
                    .replaceAll(RegExp(r'[^0-9]'), '');
                final intlPhone =
                    phone.startsWith('0') ? '62${phone.substring(1)}' : phone;
                final message = Uri.encodeComponent(
                    'Halo ${booking.customerName}, kami dari Geminiflo_ ingin menginformasikan tentang pesanan ${booking.bookingCode} Anda.');
                final uri =
                    Uri.parse('https://wa.me/$intlPhone?text=$message');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              width: double.infinity,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Batalkan Booking',
              type: ButtonType.danger,
              onPressed: booking.status == BookingStatus.pendingPayment ||
                      booking.status == BookingStatus.confirmed
                  ? () async {
                      await ref
                          .read(myBookingsProvider.notifier)
                          .cancelBooking(booking.id);
                      if (context.mounted) context.pop();
                    }
                  : null,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

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
            child: Text(title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _Row(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}
