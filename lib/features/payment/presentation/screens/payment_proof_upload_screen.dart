import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/payment_provider.dart';

class PaymentProofUploadScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentProofUploadScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PaymentProofUploadScreen> createState() =>
      _PaymentProofUploadScreenState();
}

class _PaymentProofUploadScreenState
    extends ConsumerState<PaymentProofUploadScreen> {
  String? _selectedImagePath;

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final notifier = ref.read(paymentProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Upload Bukti Pembayaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pastikan bukti transfer terbaca dengan jelas',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Upload area
            GestureDetector(
              onTap: () {
                // In real app: image_picker
                setState(() => _selectedImagePath = 'mock_proof.jpg');
              },
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: _selectedImagePath != null
                      ? AppColors.statusSuccessBg
                      : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedImagePath != null
                        ? AppColors.statusSuccess
                        : AppColors.border,
                    width: _selectedImagePath != null ? 1.5 : 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedImagePath != null
                          ? Icons.check_circle_outline
                          : Icons.upload_file_outlined,
                      color: _selectedImagePath != null
                          ? AppColors.statusSuccess
                          : AppColors.textMuted,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedImagePath != null
                          ? 'Bukti pembayaran dipilih'
                          : 'Klik untuk pilih gambar',
                      style: TextStyle(
                        color: _selectedImagePath != null
                            ? AppColors.statusSuccess
                            : AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_selectedImagePath == null)
                      const Text(
                        'JPG, PNG atau PDF (Maks. 5MB)',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Camera option
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Kamera',
                    type: ButtonType.outlined,
                    onPressed: () =>
                        setState(() => _selectedImagePath = 'camera_proof.jpg'),
                    icon: const Icon(Icons.camera_alt_outlined,
                        size: 18, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    text: 'Galeri',
                    type: ButtonType.outlined,
                    onPressed: () =>
                        setState(() => _selectedImagePath = 'gallery_proof.jpg'),
                    icon: const Icon(Icons.photo_library_outlined,
                        size: 18, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const Spacer(),
            AppButton(
              text: 'Kirim Bukti Pembayaran',
              onPressed: _selectedImagePath == null
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      final success =
                          await notifier.uploadProof(_selectedImagePath!);
                      if (!mounted) return;
                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Bukti pembayaran berhasil dikirim! Menunggu verifikasi admin.'),
                            backgroundColor: AppColors.statusSuccess,
                          ),
                        );
                        nav.pop();
                      }
                    },
              isLoading: paymentState.isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
