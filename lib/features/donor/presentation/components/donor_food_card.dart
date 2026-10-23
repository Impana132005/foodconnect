import 'package:flutter/material.dart';
import '../../../../core/enums.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/expiry_countdown.dart';
import '../../../../models/food_model.dart';

class DonorFoodCard extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;

  const DonorFoodCard({
    super.key,
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = food.imageUrl != null && food.imageUrl!.isNotEmpty;
    final isAvailable = food.status == FoodStatus.available;
    final isReserved = food.status == FoodStatus.reserved;
    final isCompleted = food.status == FoodStatus.completed;
    final isExpired = food.status == FoodStatus.expired ||
        (isAvailable && DateTime.now().isAfter(food.expiryAt));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isReserved
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.outlineVariant,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status Strip (Stitch Pattern)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: isReserved
                      ? AppColors.bgReserved
                      : (isCompleted
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainerHigh),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15.0),
                  ),
                ),
                child: Row(
                  children: [
                    // Status Indicator Dot & Label
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: isReserved
                            ? AppColors.warning
                            : (isCompleted
                                ? AppColors.primary
                                : (isExpired
                                    ? AppColors.textTertiary
                                    : AppColors.primary)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      _getStatusLabel(isReserved, isCompleted, isExpired),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isReserved
                            ? AppColors.textReserved
                            : (isCompleted
                                ? AppColors.onPrimaryContainer
                                : (isExpired
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary)),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),

                    // Timer or Status Info (ONLY when active/reserved)
                    if (isReserved || (isAvailable && !isExpired))
                      ExpiryCountdown(
                        expiryAt: food.expiryAt,
                        size: ExpiryCountdownSize.small,
                      )
                    else if (isCompleted)
                      Text(
                        'Handover completed',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (isExpired)
                      Text(
                        'Closed',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),

              // Content Body (Balanced Thumbnail + Details)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 72x72 Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        width: 72.0,
                        height: 72.0,
                        color: AppColors.surfaceContainerHigh,
                        child: hasImage
                            ? Image.network(
                                food.imageUrl!,
                                cacheWidth: 200,
                                cacheHeight: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderIcon(),
                              )
                            : _buildPlaceholderIcon(),
                      ),
                    ),
                    const SizedBox(width: 14.0),

                    // Food Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.foodName,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              const Icon(
                                Icons.restaurant_outlined,
                                size: 14.0,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                '${food.quantity} • ${_capitalize(food.foodType.value)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (food.description.isNotEmpty) ...[
                            const SizedBox(height: 4.0),
                            Text(
                              food.description,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),

                    // Action Arrow
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: isReserved
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20.0,
                        color: isReserved
                            ? AppColors.onPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(bool isReserved, bool isCompleted, bool isExpired) {
    if (isReserved) return 'RESERVED';
    if (isCompleted) return 'COMPLETED';
    if (isExpired) return 'EXPIRED';
    return 'AVAILABLE';
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.restaurant_outlined,
        size: 32.0,
        color: AppColors.textTertiary,
      ),
    );
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}
