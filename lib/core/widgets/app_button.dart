import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum ButtonType { primary, secondary, outlined, ghost, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide? borderSide;

    switch (type) {
      case ButtonType.primary:
        bgColor = AppColors.primary;
        fgColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ButtonType.secondary:
        bgColor = AppColors.secondary;
        fgColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ButtonType.outlined:
        bgColor = Colors.transparent;
        fgColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case ButtonType.ghost:
        bgColor = Colors.transparent;
        fgColor = AppColors.textPrimary;
        borderSide = BorderSide.none;
        break;
      case ButtonType.danger:
        bgColor = AppColors.statusErrorBg;
        fgColor = AppColors.statusError;
        borderSide = const BorderSide(color: AppColors.statusError, width: 1);
        break;
    }

    final isInteractive = !isLoading && onPressed != null;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: isInteractive ? bgColor : bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: InkWell(
          onTap: isInteractive ? onPressed : null,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          icon!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          text,
                          style: AppTypography.labelLarge.copyWith(
                            color: fgColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
