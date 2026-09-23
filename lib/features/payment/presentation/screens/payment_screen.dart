import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/payment.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger load after first frame so ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).initialise(
            bookingId: widget.bookingId,
            amount: 0.0, // amount will be fetched from backend
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final notifier = ref.read(paymentProvider.notifier);

    if (paymentState.isLoading && paymentState.payment == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(),
      );
    }

    final payment = paymentState.payment;
    final methods = paymentState.methods;
    final selectedIndex = paymentState.selectedMethodIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment status
            if (payment != null) ...[
              _PaymentStatusBanner(payment: payment),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Amount
            if (payment != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatIDR(payment.amount),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (payment.status == PaymentStatus.unpaid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Batas waktu: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(payment.deadline)}',
                          style: const TextStyle(
                            color: AppColors.statusError,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            if (payment?.status == PaymentStatus.unpaid ||
                payment?.status == PaymentStatus.rejected) ...[
              const Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Method tabs
              ...List.generate(methods.length, (i) {
                final method = methods[i];
                final isSelected = i == selectedIndex;
                return GestureDetector(
                  onTap: () => notifier.selectMethod(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _iconForMethod(method.type),
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (method.accountNumber != null)
                                Text(
                                  method.accountNumber!,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Use plain checkbox-style indicator to avoid deprecated Radio params
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Account details
              if (methods.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _AccountDetails(method: methods[selectedIndex]),
              ],

              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Upload Bukti Pembayaran',
                onPressed: () => context.push(
                  RouteNames.paymentPath(widget.bookingId),
                  extra: {'mode': 'upload'},
                ),
                width: double.infinity,
                icon: const Icon(Icons.upload_outlined, size: 20, color: Colors.white),
              ),
            ],

            if (payment?.status == PaymentStatus.waitingVerification) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.statusWarningBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.statusWarning.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.hourglass_empty,
                        color: AppColors.statusWarning, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Menunggu Verifikasi Admin',
                      style: TextStyle(
                        color: AppColors.statusWarning,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bukti pembayaran Anda sedang diverifikasi oleh admin. Biasanya membutuhkan waktu 1-2 jam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForMethod(String type) {
    switch (type) {
      case 'bank_transfer':
        return Icons.account_balance_outlined;
      case 'ewallet':
        return Icons.phone_android_outlined;
      case 'qris':
        return Icons.qr_code;
      default:
        return Icons.payment_outlined;
    }
  }
}

class _PaymentStatusBanner extends StatelessWidget {
  final Payment payment;

  const _PaymentStatusBanner({required this.payment});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (payment.status) {
      case PaymentStatus.unpaid:
        bgColor = AppColors.statusErrorBg;
        textColor = AppColors.statusError;
        icon = Icons.warning_amber_outlined;
        break;
      case PaymentStatus.waitingVerification:
        bgColor = AppColors.statusWarningBg;
        textColor = AppColors.statusWarning;
        icon = Icons.hourglass_empty;
        break;
      case PaymentStatus.verified:
        bgColor = AppColors.statusSuccessBg;
        textColor = AppColors.statusSuccess;
        icon = Icons.verified_outlined;
        break;
      case PaymentStatus.rejected:
        bgColor = AppColors.statusErrorBg;
        textColor = AppColors.statusError;
        icon = Icons.cancel_outlined;
        break;
      case PaymentStatus.expired:
        bgColor = AppColors.surfaceContainerHigh;
        textColor = AppColors.textMuted;
        icon = Icons.timer_off_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            payment.status.label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDetails extends StatelessWidget {
  final PaymentMethod method;

  const _AccountDetails({required this.method});

  @override
  Widget build(BuildContext context) {
    if (method.accountNumber == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Rekening ${method.name}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                method.accountNumber!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: method.accountNumber!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor rekening disalin'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.copy_outlined,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Salin',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (method.accountName != null)
            Text(
              'a.n. ${method.accountName}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
