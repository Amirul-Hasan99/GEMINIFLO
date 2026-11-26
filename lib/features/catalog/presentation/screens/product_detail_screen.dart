import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/entities/product.dart';
import '../providers/catalog_provider.dart';
import '../../../reviews/presentation/providers/review_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final favorites = ref.watch(favoritesProvider);
    final isFavorited = favorites.any((p) => p.id == productId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: LoadingWidget(),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.catalog),
            ),
          ),
          body: app.CustomErrorWidget(
            message: e.toString(),
            onRetry: () => ref.refresh(productDetailProvider(productId)),
          ),
        ),
        data: (product) => CustomScrollView(
          slivers: [
            // Hero image app bar
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(RouteNames.catalog),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: isFavorited ? Colors.red : Colors.white,
                  ),
                  onPressed: () => ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(product.id),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: product.imageUrls.isNotEmpty
                    ? ProductImage(source: product.imageUrls.first)
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0F382A), Color(0xFF154D39)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_florist,
                            color: AppColors.secondary,
                            size: 80,
                          ),
                        ),
                      ),
              ),
            ),
            // Product info
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surfaceWhite,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge.fromStatus(product.availabilityStatus),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.sku,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.categoryName,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: AppSpacing.md),
                    // Specs row
                    Row(
                      children: [
                        _SpecItem(
                          icon: Icons.straighten_outlined,
                          label: 'Ukuran',
                          value: product.dimensions,
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        _SpecItem(
                          icon: Icons.inventory_2_outlined,
                          label: 'Stok',
                          value: '${product.stockAvailable} tersedia',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: AppSpacing.md),
                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.formatIDR(product.pricePerDay),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            '/ 24 jam',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            // Description
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.xl),
                color: AppColors.surfaceWhite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description ?? 'Papan bunga premium dari Geminiflo_ untuk setiap momen istimewa Anda.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.xl),
                color: AppColors.surfaceWhite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rating dan Ulasan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ref
                        .watch(productReviewsProvider(product.id))
                        .when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) =>
                              const Text('Ulasan belum dapat dimuat.'),
                          data: (reviews) => reviews.isEmpty
                              ? const Text(
                                  'Belum ada ulasan untuk papan bunga ini.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                )
                              : Column(
                                  children: reviews
                                      .take(8)
                                      .map(
                                        (review) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.account_circle_outlined,
                                                color: AppColors.textMuted,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      review.customerName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${List.filled(review.rating, '★').join()}${List.filled(5 - review.rating, '☆').join()}',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFFB7791F,
                                                        ),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (review
                                                        .comment
                                                        .isNotEmpty)
                                                      Text(
                                                        review.comment,
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                  ],
                ),
              ),
            ),
            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      // Bottom CTAs
      bottomNavigationBar: productAsync
          .whenData(
            (product) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                border: const Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Cek Ketersediaan',
                        type: ButtonType.outlined,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) =>
                                _AvailabilitySheet(product: product),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Booking Sekarang',
                        onPressed: product.availabilityStatus == 'unavailable'
                            ? null
                            : () => context.push(
                                RouteNames.bookingPath(product.id),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .value,
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvailabilitySheet extends StatefulWidget {
  final Product product;

  const _AvailabilitySheet({required this.product});

  @override
  State<_AvailabilitySheet> createState() => _AvailabilitySheetState();
}

class _AvailabilitySheetState extends State<_AvailabilitySheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dayAfter = DateTime.now().add(const Duration(days: 2));
    final daysUntilSat = (DateTime.saturday - DateTime.now().weekday + 7) % 7;
    final nextWeekend = DateTime.now().add(
      Duration(days: daysUntilSat == 0 ? 7 : daysUntilSat),
    );

    final isAvailable =
        widget.product.availabilityStatus != 'unavailable' &&
        widget.product.stockAvailable > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag indicator
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cek Ketersediaan Slot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              StatusBadge.availability(widget.product.availabilityStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Stock Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stok Rangka Fisik: ${widget.product.stockAvailable} Unit Siap Sewa',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total armada: ${widget.product.stockTotal} unit • Dimensi: ${widget.product.dimensions}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date Selection Section
          const Text(
            'Pilih Tanggal Acara Anda:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Quick selection chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DateChip(
                  label: 'Besok (${DateFormatter.formatShort(tomorrow)})',
                  isSelected:
                      _selectedDate.day == tomorrow.day &&
                      _selectedDate.month == tomorrow.month,
                  onTap: () => setState(() => _selectedDate = tomorrow),
                ),
                const SizedBox(width: 8),
                _DateChip(
                  label: 'Lusa (${DateFormatter.formatShort(dayAfter)})',
                  isSelected:
                      _selectedDate.day == dayAfter.day &&
                      _selectedDate.month == dayAfter.month,
                  onTap: () => setState(() => _selectedDate = dayAfter),
                ),
                const SizedBox(width: 8),
                _DateChip(
                  label: 'Sabtu (${DateFormatter.formatShort(nextWeekend)})',
                  isSelected:
                      _selectedDate.day == nextWeekend.day &&
                      _selectedDate.month == nextWeekend.month,
                  onTap: () => setState(() => _selectedDate = nextWeekend),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Selected Date Box
          InkWell(
            onTap: _pickCustomDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Acara Terpilih (Klik untuk ubah)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          DateFormatter.formatFull(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Availability Result Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.statusSuccessBg
                  : AppColors.statusErrorBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isAvailable
                    ? AppColors.statusSuccess
                    : AppColors.statusError,
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isAvailable
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: isAvailable
                      ? AppColors.statusSuccess
                      : AppColors.statusError,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable
                            ? 'Papan Bunga TERSEDIA untuk Tanggal Ini'
                            : 'Slot Tanggal Ini Penuh / Tidak Tersedia',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isAvailable
                              ? AppColors.statusSuccess
                              : AppColors.statusError,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAvailable
                            ? 'Durasi sewa 24 Jam. Gratis pengiriman antar-jemput & instalasi oleh Florist Geminiflo (atau opsi pick-up).'
                            : 'Silakan pilih tanggal lain atau konsultasikan dengan admin florist kami.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isAvailable
                              ? const Color(0xFF154D39)
                              : AppColors.statusError,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          AppButton(
            text: isAvailable
                ? 'Lanjut Booking untuk Tanggal Ini'
                : 'Pilih Tanggal Lain',
            onPressed: isAvailable
                ? () {
                    Navigator.of(context).pop();
                    context.push(
                      RouteNames.bookingPath(widget.product.id),
                      extra: _selectedDate,
                    );
                  }
                : _pickCustomDate,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
