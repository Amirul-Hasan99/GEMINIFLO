import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/empty_widget.dart';

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Verifikasi Pembayaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: const EmptyWidget(
        message: 'Belum Ada Bukti Pembayaran',
        subMessage: 'Bukti pembayaran dari pelanggan akan muncul di sini',
        icon: Icons.receipt_long_outlined,
      ),
    );
  }
}
