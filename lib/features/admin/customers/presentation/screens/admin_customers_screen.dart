import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/empty_widget.dart';

class AdminCustomersScreen extends StatelessWidget {
  const AdminCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Pelanggan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: const EmptyWidget(
        message: 'Belum Ada Data Pelanggan',
        subMessage: 'Data pelanggan akan muncul setelah ada booking',
        icon: Icons.people_outlined,
      ),
    );
  }
}
