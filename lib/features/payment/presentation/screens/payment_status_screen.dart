import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentStatusScreen extends StatelessWidget {
  final String bookingId;

  const PaymentStatusScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.orders),
        ),
        title: const Text('Status Pembayaran',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: const Center(
        child: Text('Payment status screen'),
      ),
    );
  }
}
