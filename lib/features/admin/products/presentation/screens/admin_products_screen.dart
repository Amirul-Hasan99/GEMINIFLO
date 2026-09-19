import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/empty_widget.dart';
import '../../../../../core/widgets/loading_widget.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../../features/catalog/presentation/providers/catalog_provider.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kelola Produk',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RouteNames.adminProductAdd),
            tooltip: 'Tambah Produk',
          ),
        ],
      ),
      body: catalogState.isLoading
          ? const LoadingWidget()
          : catalogState.products.isEmpty
              ? const EmptyWidget(
                  message: 'Belum Ada Produk',
                  subMessage: 'Tambahkan produk papan bunga pertama Anda',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: catalogState.products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final product = catalogState.products[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_florist,
                              color: AppColors.primary),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.sku,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                StatusBadge.fromStatus(
                                    product.availabilityStatus),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(
                                      product.pricePerDay),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.primary, size: 20),
                              onPressed: () => context.push(
                                RouteNames.adminProductEditPath(product.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.adminProductAdd),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}
