import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final catalogState = ref.watch(catalogProvider);
    final featuredProducts = catalogState.products
        .where((p) => p.isFeatured && p.availabilityStatus != 'unavailable')
        .take(4)
        .toList();

    final user = auth.user;
    final headerName = user?.username?.isNotEmpty == true
        ? '@${user!.username}'
        : user?.name.split(' ').first ?? 'Pengguna';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 17
        ? 'Selamat Siang'
        : 'Selamat Malam';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceWhite,
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: user?.avatar?.isNotEmpty == true
                          ? ProductImage(
                              source: user!.avatar,
                              fit: BoxFit.cover,
                            )
                          : const AppLogo(size: 42, isCircle: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting,',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          headerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        tooltip: 'Notifikasi',
                        onPressed: () => context.push(RouteNames.notifications),
                        icon: const Icon(
                          LucideIcons.bell,
                          color: AppColors.primary,
                        ),
                      ),
                      if (ref.watch(unreadNotificationsCountProvider) > 0)
                        const Positioned(
                          right: 10,
                          top: 9,
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: AppColors.secondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.go(RouteNames.catalog),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, size: 19, color: AppColors.primary),
                      SizedBox(width: 9),
                      Text(
                        'Cari papan bunga...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.go(RouteNames.catalog),
                child: Container(
                  height: 78,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1B6B4D)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'LAYANAN GEMINIFLO',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Antar, pasang, dan jemput gratis',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Papan bunga untuk setiap momen',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.local_florist,
                        size: 34,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pilihan untuk Anda',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(RouteNames.catalog),
                    child: const Text(
                      'Lihat semua',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: catalogState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : featuredProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'Produk unggulan belum tersedia',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 760 ? 4 : 2;
                          final rows = (featuredProducts.length / columns)
                              .ceil();
                          return GridView.builder(
                            padding: const EdgeInsets.only(bottom: 4),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: featuredProducts.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  mainAxisExtent:
                                      (constraints.maxHeight -
                                          (rows - 1) * 10) /
                                      rows,
                                ),
                            itemBuilder: (context, index) =>
                                _FeaturedProductCard(
                                  product: featuredProducts[index],
                                  onTap: () => context.push(
                                    RouteNames.productDetailPath(
                                      featuredProducts[index].id,
                                    ),
                                  ),
                                  onFavorite: () => ref
                                      .read(favoritesProvider.notifier)
                                      .toggleFavorite(
                                        featuredProducts[index].id,
                                      ),
                                ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1:
              context.go(RouteNames.catalog);
              break;
            case 2:
              context.go(RouteNames.orders);
              break;
            case 3:
              context.go(RouteNames.profile);
              break;
          }
        },
      ),
    );
  }
}

class _FeaturedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _FeaturedProductCard({
    required this.product,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: product.imageUrls.isEmpty
                        ? const ColoredBox(
                            color: AppColors.background,
                            child: Icon(
                              Icons.local_florist,
                              color: AppColors.primary,
                            ),
                          )
                        : ProductImage(
                            source: product.imageUrls.first,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Favoritkan ${product.name}',
                        onPressed: onFavorite,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        icon: Icon(
                          product.isFavorited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 17,
                          color: AppColors.statusError,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              CurrencyFormatter.formatIDR(product.pricePerDay),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
