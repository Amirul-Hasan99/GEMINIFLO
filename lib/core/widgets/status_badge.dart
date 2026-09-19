import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BadgeVariant { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.showDot = true,
  });

  /// Convenience constructor for product availability status strings
  factory StatusBadge.availability(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const StatusBadge(
            label: 'Tersedia', variant: BadgeVariant.success);
      case 'limited':
        return const StatusBadge(
            label: 'Terbatas', variant: BadgeVariant.warning);
      case 'unavailable':
        return const StatusBadge(
            label: 'Habis', variant: BadgeVariant.error);
      default:
        return StatusBadge(label: status, variant: BadgeVariant.neutral);
    }
  }

  factory StatusBadge.fromStatus(String status) {
    final lower = status.toLowerCase();

    if (lower.contains('tersedia') ||
        lower.contains('lunas') ||
        lower.contains('terverifikasi') ||
        lower.contains('verified') ||
        lower.contains('confirmed') ||
        lower.contains('ready') ||
        lower.contains('completed') ||
        lower.contains('selesai')) {
      return StatusBadge(label: status, variant: BadgeVariant.success);
    } else if (lower.contains('sisa') ||
        lower.contains('terbatas') ||
        lower.contains('menunggu') ||
        lower.contains('pending') ||
        lower.contains('waiting') ||
        lower.contains('verifikasi')) {
      return StatusBadge(label: status, variant: BadgeVariant.warning);
    } else if (lower.contains('penuh') ||
        lower.contains('habis') ||
        lower.contains('ditolak') ||
        lower.contains('rejected') ||
        lower.contains('cancelled') ||
        lower.contains('batal') ||
        lower.contains('expired') ||
        lower.contains('kedaluwarsa')) {
      return StatusBadge(label: status, variant: BadgeVariant.error);
    } else if (lower.contains('proses') || lower.contains('processing')) {
      return StatusBadge(label: status, variant: BadgeVariant.info);
    }

    return StatusBadge(label: status, variant: BadgeVariant.neutral);
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case BadgeVariant.success:
        bg = AppColors.statusSuccessBg;
        fg = AppColors.statusSuccess;
        break;
      case BadgeVariant.warning:
        bg = AppColors.statusWarningBg;
        fg = AppColors.statusWarning;
        break;
      case BadgeVariant.error:
        bg = AppColors.statusErrorBg;
        fg = AppColors.statusError;
        break;
      case BadgeVariant.info:
        bg = AppColors.statusInfoBg;
        fg = AppColors.statusInfo;
        break;
      case BadgeVariant.neutral:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
