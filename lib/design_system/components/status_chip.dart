import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final String? customLabel;

  const StatusChip({super.key, required this.status, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase();

    Color bgColor;
    Color textColor;
    Color dotColor;
    bool isHollowDot = false;
    bool showCheck = false;
    String label;

    switch (statusLower) {
      case 'available':
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.onPrimaryContainer;
        dotColor = AppColors.primary;
        label = customLabel ?? 'Available';
        break;
      case 'reserved':
      case 'active':
        bgColor = AppColors.bgReserved;
        textColor = AppColors.textReserved;
        dotColor = AppColors.warning;
        label =
            customLabel ?? (statusLower == 'reserved' ? 'Reserved' : 'Active');
        break;
      case 'otp_verified':
      case 'verified':
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.onPrimaryContainer;
        dotColor = AppColors.primary;
        showCheck = true;
        label = customLabel ?? 'Code verified';
        break;
      case 'completed':
        bgColor = AppColors.surfaceContainerHigh;
        textColor = AppColors.textSecondary;
        dotColor = AppColors.textTertiary;
        label = customLabel ?? 'Completed';
        break;
      case 'expired':
        bgColor = AppColors.surfaceContainerHigh;
        textColor = AppColors.textTertiary;
        dotColor = AppColors.outline;
        isHollowDot = true;
        label = customLabel ?? 'Expired';
        break;
      case 'cancelled':
      default:
        bgColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        dotColor = AppColors.error;
        label =
            customLabel ?? (statusLower == 'cancelled' ? 'Cancelled' : status);
        break;
    }

    return Container(
      height: 24.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showCheck)
            const Padding(
              padding: EdgeInsets.only(right: 4.0),
              child: Icon(
                Icons.check_circle,
                size: 12,
                color: AppColors.primary,
              ),
            )
          else if (isHollowDot)
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 1.5),
              ),
            )
          else
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
