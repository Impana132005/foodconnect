import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/enums.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../design_system/components/confirmation_dialog.dart';
import '../../../../design_system/components/docked_cta.dart';
import '../../../../design_system/components/empty_state.dart';
import '../../../../design_system/components/loading_skeleton.dart';
import '../../../../models/food_model.dart';
import '../../../../models/reservation_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../food/presentation/providers/food_providers.dart';
import '../../../reservation/presentation/providers/reservation_providers.dart';

class DonorFoodDetailsView extends ConsumerStatefulWidget {
  final String foodId;
  const DonorFoodDetailsView({super.key, required this.foodId});

  @override
  ConsumerState<DonorFoodDetailsView> createState() =>
      _DonorFoodDetailsViewState();
}

class _DonorFoodDetailsViewState extends ConsumerState<DonorFoodDetailsView> {
  bool _isCompleting = false;
  String? _errorMessage;

  Future<void> _handleCompleteHandover({
    required Food food,
    required Reservation reservation,
  }) async {
    if (_isCompleting) return;

    final userProfileAsync = ref.read(userProfileProvider);
    final user = userProfileAsync.value;
    if (user == null) return;

    await showConfirmationDialog(
      context: context,
      title: 'Complete this donation?',
      message:
          'Confirm that you have handed the food to the receiver. This will mark the donation as completed.',
      confirmLabel: 'Complete donation',
      cancelLabel: 'Cancel',
      onConfirm: () async {
        if (_isCompleting) return;
        setState(() {
          _isCompleting = true;
          _errorMessage = null;
        });

        final repo = ref.read(reservationRepositoryProvider);
        final result = await repo.completeReservation(
          reservationId: reservation.reservationId,
          foodId: food.foodId,
          donorId: user.userId,
        );

        if (!mounted) return;

        setState(() {
          _isCompleting = false;
        });

        result.fold(
          (_) {
            // Invalidate providers
            ref.invalidate(donorFoodsProvider(user.userId));
            ref.invalidate(foodDetailsProvider(widget.foodId));
            ref.invalidate(
              reservationStreamProvider(reservation.reservationId),
            );

            // Show success bottom sheet / dialog
            _showCompletionSuccessDialog();
          },
          (error) {
            setState(() {
              _errorMessage = error;
            });
          },
        );
      },
    );
  }

  void _showCompletionSuccessDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64.0,
                  height: 64.0,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 36.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Donation completed',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'The food has been successfully handed over to the receiver. Thank you for reducing food waste!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28.0),
                AppButton(
                  text: 'Back to Dashboard',
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.donorDashboard);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodAsync = ref.watch(foodDetailsProvider(widget.foodId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.donorDashboard);
            }
          },
        ),
        title: Text('Donation details', style: AppTextStyles.titleLarge),
      ),
      body: SafeArea(
        child: foodAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: LoadingSkeleton(height: 250),
          ),
          error: (err, _) => ErrorState(
            title: 'Error loading donation details',
            description: err.toString(),
            onRetry: () => ref.invalidate(foodDetailsProvider(widget.foodId)),
          ),
          data: (food) {
            final hasImage = food.imageUrl != null && food.imageUrl!.isNotEmpty;
            final resId = food.currentReservationId;
            final isReserved = resId != null && resId.isNotEmpty;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Error Banner (if any)
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20.0,
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),
                        ],

                        // 2. Main Food Summary Card (Stitch Design)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: AppColors.outlineVariant,
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Section: Title, Metadata, Description & Thumbnail
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            food.foodName,
                                            style: AppTextStyles.titleLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            '${food.quantity} • ${_capitalize(food.foodType.value)}',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          if (food.description.isNotEmpty) ...[
                                            const SizedBox(height: 6.0),
                                            Text(
                                              food.description,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
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
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    _buildImagePlaceholder(),
                                              )
                                            : _buildImagePlaceholder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (isReserved) ...[
                                const Divider(
                                  height: 1.0,
                                  thickness: 1.0,
                                  color: AppColors.outlineVariant,
                                ),
                                // Reserved By Section
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40.0,
                                        height: 40.0,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.local_shipping_outlined,
                                          color: AppColors.primary,
                                          size: 20.0,
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'RESERVED BY',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    letterSpacing: 0.8,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                            const SizedBox(height: 2.0),
                                            Text(
                                              'Community Receiver',
                                              style: AppTextStyles.labelLarge
                                                  .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // 3. Dynamic Handover & Status Card
                        if (!isReserved) ...[
                          if (food.status == FoodStatus.available)
                            _buildStatusCard(
                              title: 'Waiting for a receiver',
                              subtitle:
                                  "You'll be notified when someone reserves this donation.",
                              icon: Icons.hourglass_empty_outlined,
                              color: AppColors.primary,
                              bgColor: AppColors.surfaceContainer,
                            )
                          else if (food.status == FoodStatus.expired)
                            _buildStatusCard(
                              title: 'Food expired',
                              subtitle:
                                  'This item passed its pickup window and is no longer available.',
                              icon: Icons.timer_off_outlined,
                              color: AppColors.textTertiary,
                              bgColor: AppColors.surfaceContainerHigh,
                            )
                          else
                            _buildStatusCard(
                              title: 'Donation completed',
                              subtitle:
                                  'Food was successfully handed over and closed.',
                              icon: Icons.check_circle_outlined,
                              color: AppColors.success,
                              bgColor: AppColors.primaryContainer,
                            ),
                        ] else ...[
                          Consumer(
                            builder: (context, ref, child) {
                              final resAsync = ref.watch(
                                reservationStreamProvider(resId),
                              );

                              return resAsync.when(
                                loading: () =>
                                    const LoadingSkeleton(height: 120),
                                error: (err, _) => InkWell(
                                  onTap: () => ref.invalidate(
                                    reservationStreamProvider(resId),
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorContainer,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: AppColors.error
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.refresh,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Tap to retry loading pickup details.',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: AppColors
                                                      .onErrorContainer,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                data: (reservation) {
                                  if (reservation == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final isOtpVerified = reservation.status ==
                                          ReservationStatus.otpVerified ||
                                      reservation.otpVerified == true;
                                  final isCompleted = reservation.status ==
                                      ReservationStatus.completed;

                                  if (isCompleted) {
                                    return _buildStatusCard(
                                      title: 'Donation completed',
                                      subtitle:
                                          'Handover was successfully completed.',
                                      icon: Icons.check_circle_outlined,
                                      color: AppColors.success,
                                      bgColor: AppColors.primaryContainer,
                                    );
                                  }

                                  if (isOtpVerified) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // A. Prominent Verified Handover Banner
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16.0),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                            border: Border.all(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.35),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            4.0),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check,
                                                      color:
                                                          AppColors.onPrimary,
                                                      size: 14.0,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8.0),
                                                  Text(
                                                    'PICKUP VERIFIED',
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color:
                                                              AppColors.primary,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 0.6,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10.0),
                                              Text(
                                                'Ready for handover',
                                                style: AppTextStyles.titleMedium
                                                    .copyWith(
                                                      color: AppColors
                                                          .onPrimaryContainer,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 18.0,
                                                    ),
                                              ),
                                              const SizedBox(height: 4.0),
                                              Text(
                                                'The receiver has confirmed the pickup code. You can now hand over the food.',
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      color: AppColors
                                                          .onPrimaryContainer,
                                                      height: 1.35,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16.0),

                                        // B. Next Step Guidance Card
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16.0),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceContainer,
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                            border: Border.all(
                                              color: AppColors.outlineVariant,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .arrow_circle_right_outlined,
                                                    color: AppColors.primary,
                                                    size: 20.0,
                                                  ),
                                                  const SizedBox(width: 8.0),
                                                  Text(
                                                    'Next step',
                                                    style: AppTextStyles
                                                        .labelMedium
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8.0),
                                              Text(
                                                'Hand the food to the verified receiver, then tap Drop & Done to complete the donation.',
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                      height: 1.4,
                                                    ),
                                              ),
                                              const SizedBox(height: 8.0),
                                              Text(
                                                'This records the finished handover in Surplus and removes the listing from active pickups.',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                      color: AppColors
                                                          .textTertiary,
                                                      height: 1.3,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  // Pickup in progress + OTP Display Card
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgReserved,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.schedule,
                                              color: AppColors.warning,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Pickup in progress',
                                                    style: AppTextStyles
                                                        .labelLarge
                                                        .copyWith(
                                                          color: AppColors
                                                              .textReserved,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Receiver is heading to your location.',
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                          color: AppColors
                                                              .textReserved,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16.0),

                                      // OTP Card with individual digit boxes
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20.0),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: AppColors.outlineVariant,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Share this code when receiver arrives',
                                              style: AppTextStyles.labelMedium
                                                  .copyWith(
                                                    color: AppColors
                                                        .textSecondary,
                                                  ),
                                            ),
                                            const SizedBox(height: 14),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: (reservation
                                                          .otp.isNotEmpty
                                                      ? reservation.otp
                                                          .split('')
                                                      : [
                                                          '-',
                                                          '-',
                                                          '-',
                                                          '-',
                                                          '-',
                                                          '-',
                                                        ])
                                                  .map(
                                                    (digit) => Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 4.0,
                                                      ),
                                                      width: 40.0,
                                                      height: 48.0,
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .surfaceContainerHigh,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          digit,
                                                          style: AppTextStyles
                                                              .titleLarge
                                                              .copyWith(
                                                                color: AppColors
                                                                    .primary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 4. Primary Action: Docked CTA Footer
                if (isReserved)
                  Consumer(
                    builder: (context, ref, child) {
                      final resAsync = ref.watch(
                        reservationStreamProvider(resId),
                      );

                      return resAsync.maybeWhen(
                        data: (reservation) {
                          if (reservation != null &&
                              (reservation.status ==
                                      ReservationStatus.otpVerified ||
                                  reservation.otpVerified == true)) {
                            return DockedCTA(
                              child: AppButton(
                                text: 'Drop & Done',
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18.0,
                                ),
                                isLoading: _isCompleting,
                                onPressed: () => _handleCompleteHandover(
                                  food: food,
                                  reservation: reservation,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
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
