import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? extra;

  const BookingSuccessScreen({super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    final bookingCode = extra?['bookingCode'] as String? ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.statusSuccessBg,
                  border: Border.all(
                      color: AppColors.statusSuccess.withValues(alpha: 0.3),
                      width: 2),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.statusSuccess,
                  size: 64,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Booking Berhasil!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Booking Anda dengan kode $bookingCode telah berhasil dibuat. Segera lakukan pembayaran sebelum batas waktu.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              AppButton(
                text: 'Lihat Pesanan Saya',
                onPressed: () => context.go(RouteNames.orders),
                width: double.infinity,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: 'Kembali ke Beranda',
                type: ButtonType.outlined,
                onPressed: () => context.go(RouteNames.home),
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
