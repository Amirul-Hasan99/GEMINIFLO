import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/empty_widget.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../../../../core/widgets/loading_widget.dart';
import '../providers/catalog_provider.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final catalogNotifier = ref.read(catalogProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Katalog Papan Bunga',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => _showSortSheet(context, catalogNotifier),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: TextField(
              controller: _searchCtrl,
              onChanged: catalogNotifier.setSearch,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari papan bunga...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          catalogNotifier.setSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceWhite,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Category filter chips
          categoriesAsync.when(
            data: (categories) => SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 8),
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final isAll = catalogState.filter.categoryId == null;
                    return _CategoryChip(
                      label: 'Semua',
                      isActive: isAll,
                      onTap: () => catalogNotifier.setCategory(null),
                    );
                  }
                  final cat = categories[i - 1];
                  final isActive =
                      catalogState.filter.categoryId == cat.id;
                  return _CategoryChip(
                    label: cat.name,
                    isActive: isActive,
                    onTap: () => catalogNotifier.setCategory(
                        isActive ? null : cat.id),
                  );
                },
              ),
            ),
            loading: () => const SizedBox(height: 48),
            error: (_, _) => const SizedBox(height: 48),
          ),
          // Product grid
          Expanded(
            child: catalogState.isLoading
                ? const LoadingWidget()
                : catalogState.error != null
                    ? app.CustomErrorWidget(
                        message: catalogState.error!,
                        onRetry: catalogNotifier.loadProducts,
                      )
                    : catalogState.products.isEmpty
                        ? const EmptyWidget(
                            message: 'Tidak ada papan bunga ditemukan',
                            subMessage:
                                'Coba ubah filter atau kata kunci pencarian',
                          )
                        : RefreshIndicator(
                            onRefresh: catalogNotifier.loadProducts,
                            color: AppColors.primary,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.62,
                              ),
                              itemCount: catalogState.products.length,
                              itemBuilder: (context, i) {
                                final product = catalogState.products[i];
                                return ProductCard(
                                  product: product,
                                  onFavorite: () => ref
                                      .read(favoritesProvider.notifier)
                                      .toggleFavorite(product.id),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (i) => _handleNavTap(context, i),
      ),
    );
  }

  void _handleNavTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        break;
      case 2:
        context.go(RouteNames.orders);
        break;
      case 3:
        context.go(RouteNames.profile);
        break;
    }
  }

  void _showSortSheet(BuildContext context, CatalogNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Urutkan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SortOption(
              label: 'Harga Terendah',
              onTap: () {
                notifier.setSortBy('price_asc');
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'Harga Tertinggi',
              onTap: () {
                notifier.setSortBy('price_desc');
                Navigator.pop(context);
              },
            ),
            _SortOption(
              label: 'Reset',
              onTap: () {
                notifier.setSortBy(null);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SortOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textMuted,
      ),
    );
  }
}
