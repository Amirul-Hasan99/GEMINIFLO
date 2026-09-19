import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;
  final Border? border;
  final bool hasShadow;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.hasShadow = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.cardRadius;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: border ??
                Border.all(color: AppColors.borderLight, width: 1),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
