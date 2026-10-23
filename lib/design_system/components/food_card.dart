import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';
import 'expiry_countdown.dart';

class FoodCard extends StatelessWidget {
  final String title;
  final String quantity;
  final String foodType; // 'cooked' or 'packed'
  final String status;
  final String? subtitle; // e.g. Donor Organization name
  final String? distance;
  final DateTime expiryAt;
  final String? imageUrl;
  final VoidCallback? onTap;

  const FoodCard({
    super.key,
    required this.title,
    required this.quantity,
    required this.foodType,
    required this.status,
    this.subtitle,
    this.distance,
    this.preparedAt,
    required this.expiryAt,
    this.imageUrl,
    this.onTap,
  });

  final DateTime? preparedAt;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final donorName = subtitle ?? 'Community Kitchen';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
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
              // Top Hero Image Banner (130dp) with Overlay Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16.0),
                    ),
                    child: Container(
                      height: 130.0,
                      width: double.infinity,
                      color: AppColors.surfaceContainerHigh,
                      child: hasImage
                          ? Image.network(
                              imageUrl!,
                              cacheWidth: 800,
                              cacheHeight: 400,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderIcon(),
                            )
                          : _buildPlaceholderIcon(),
                    ),
                  ),

                  // Top-Left Expiry Countdown Badge
                  Positioned(
                    top: 10.0,
                    left: 10.0,
                    child: ExpiryCountdown(
                      expiryAt: expiryAt,
                      size: ExpiryCountdownSize.small,
                    ),
                  ),

                  // Top-Right Food Type Pill
                  Positioned(
                    top: 10.0,
                    right: 10.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4.0,
                          ),
                        ],
                      ),
                      child: Text(
                        _capitalize(foodType),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Card Body
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 16.0,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            donorName,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    const Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: AppColors.outlineVariant,
                    ),
                    const SizedBox(height: 12.0),

                    // Bottom Row: Servings, Distance, Action
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.restaurant_outlined,
                              size: 16.0,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              quantity,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (distance != null && distance!.isNotEmpty) ...[
                          const SizedBox(width: 16.0),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16.0,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                distance!,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18.0,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.restaurant_outlined,
        size: 36.0,
        color: AppColors.textTertiary,
      ),
    );
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}
