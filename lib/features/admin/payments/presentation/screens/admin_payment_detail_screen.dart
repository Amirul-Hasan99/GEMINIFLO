import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class AdminPaymentDetailScreen extends StatelessWidget {
  final String paymentId;

  const AdminPaymentDetailScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Detail Pembayaran #$paymentId',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: const Center(child: Text('Admin Payment Detail')),
    );
  }
}
