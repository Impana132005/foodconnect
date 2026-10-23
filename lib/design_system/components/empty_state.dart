import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.eco_outlined,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32.0, color: AppColors.primary),
            ),
            const SizedBox(height: 20.0),
            Text(
              title,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 24.0),
              SizedBox(
                width: 220.0,
                child: AppButton(
                  text: actionLabel!,
                  onPressed: onActionPressed!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String title;
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Unable to complete action',
    required String description,
    this.onRetry,
  }) : errorMessage = description;

  const ErrorState.withMessage({
    super.key,
    required this.errorMessage,
    this.title = 'Unable to complete action',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.errorContainer,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_outlined,
                size: 36.0,
                color: AppColors.error,
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6.0),
              Text(
                errorMessage,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16.0),
                SizedBox(
                  width: 140.0,
                  child: SecondaryButton(
                    text: 'Try again',
                    onPressed: onRetry!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
