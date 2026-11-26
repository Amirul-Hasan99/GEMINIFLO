import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../reviews/presentation/providers/review_provider.dart';

class AdminReviewsScreen extends ConsumerWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(adminReviewsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Ulasan Pelanggan'),
      ),
      body: reviews.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Gagal memuat ulasan: $error')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada ulasan pelanggan.'))
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.refresh(adminReviewsProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final review = items[index];
                    return Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review.customerName,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${List.filled(review.rating, '★').join()}${List.filled(5 - review.rating, '☆').join()}',
                              style: const TextStyle(
                                color: Color(0xFFB7791F),
                                fontSize: 17,
                              ),
                            ),
                            if (review.comment.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(review.comment),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Booking ${review.bookingId} · ${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
