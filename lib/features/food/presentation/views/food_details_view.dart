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
import '../../../../design_system/components/expiry_countdown.dart';
import '../../../../design_system/components/loading_skeleton.dart';
import '../../../../design_system/components/status_chip.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../reservation/presentation/providers/reservation_providers.dart';
import '../components/pickup_location_card.dart';
import '../providers/food_providers.dart';
import '../../../../services/location_service.dart';

class FoodDetailsView extends ConsumerStatefulWidget {
  final String foodId;
  const FoodDetailsView({super.key, required this.foodId});

  @override
  ConsumerState<FoodDetailsView> createState() => _FoodDetailsViewState();
}

class _FoodDetailsViewState extends ConsumerState<FoodDetailsView> {
  bool _isReserving = false;
  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      final loc = await LocationService().getCurrentLocation();
      if (mounted && loc != null) {
        setState(() {
          _userLatitude = loc.latitude;
          _userLongitude = loc.longitude;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleReserveFood(String currentUserId, String donorId) async {
    if (_isReserving) return;
    if (currentUserId == donorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't reserve your own donation.")),
      );
      return;
    }

    await showConfirmationDialog(
      context: context,
      title: 'Reserve this food?',
      message: "You'll have 30 minutes from now to complete the pickup.",
      confirmLabel: 'Reserve this food',
      cancelLabel: 'Cancel',
      onConfirm: () async {
        setState(() {
          _isReserving = true;
        });

        final reservationRepo = ref.read(reservationRepositoryProvider);
        final result = await reservationRepo.reserveFood(widget.foodId);

        if (!mounted) return;

        setState(() {
          _isReserving = false;
        });

        result.fold(
          (reservation) {
            ref.invalidate(availableFoodsStreamProvider);
            ref.invalidate(foodDetailsProvider(widget.foodId));
            context.pushReplacement(
              '${AppRoutes.reservation}/${reservation.reservationId}',
            );
          },
          (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.error),
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final foodAsync = ref.watch(foodDetailsProvider(widget.foodId));
    final currentUser = ref.watch(userProfileProvider).value;

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
              context.go(AppRoutes.receiverDashboard);
            }
          },
        ),
        title: Text('Food details', style: AppTextStyles.titleLarge),
      ),
      body: SafeArea(
        child: foodAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: LoadingSkeleton(height: 250),
          ),
          error: (err, _) => ErrorState(
            title: 'Error loading food details',
            description: err.toString(),
            onRetry: () => ref.invalidate(foodDetailsProvider(widget.foodId)),
          ),
          data: (food) {
            final isAvailable = food.status == FoodStatus.available;
            final isOwnFood =
                currentUser != null && currentUser.userId == food.donorId;
            final hasImage = food.imageUrl != null && food.imageUrl!.isNotEmpty;
            final isExpired = DateTime.now().isAfter(food.expiryAt);

            String buttonText = 'Reserve this food';
            String? disabledReason;
            if (isOwnFood) {
              buttonText = 'Reserve this food';
              disabledReason = "You can't reserve your own donation";
            } else if (isExpired || food.status == FoodStatus.expired) {
              buttonText = 'Food expired';
              disabledReason = 'This food item has expired';
            } else if (!isAvailable) {
              buttonText = 'Already reserved';
              disabledReason = 'Another receiver reserved this item';
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Image Slot (20dp radius top corners, overlaid chips)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: Container(
                            height: 200.0,
                            width: double.infinity,
                            color: AppColors.surfaceContainerHigh,
                            child: Stack(
                              children: [
                                if (hasImage)
                                  Image.network(
                                    food.imageUrl!,
                                    cacheWidth: 800,
                                    cacheHeight: 400,
                                    width: double.infinity,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholderIcon(),
                                  )
                                else
                                  _buildPlaceholderIcon(),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: StatusChip(status: food.status.value),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: ExpiryCountdown(
                                    expiryAt: food.expiryAt,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title & Metadata
                        Text(food.foodName, style: AppTextStyles.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${_capitalize(food.foodType.value)} · ${food.quantity}',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        if (food.description.isNotEmpty) ...[
                          Text(
                            food.description,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: AppColors.outlineVariant,
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                icon: Icons.category_outlined,
                                label: 'Category',
                                value:
                                    '${_capitalize(food.foodType.value)} food',
                              ),
                              const Divider(
                                height: 20,
                                color: AppColors.outlineVariant,
                              ),
                              _buildInfoRow(
                                icon: Icons.timer_outlined,
                                label: 'Expiry window',
                                valueWidget: ExpiryCountdown(
                                  expiryAt: food.expiryAt,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pickup Location Card
                        // Pickup Location Map Card
                        PickupLocationCard(
                          latitude: food.latitude,
                          longitude: food.longitude,
                          placeName: '${food.foodName} Pickup Location',
                          distanceKm: (food.latitude != null &&
                                  food.longitude != null &&
                                  _userLatitude != null &&
                                  _userLongitude != null)
                              ? LocationService().calculateDistance(
                                  _userLatitude!,
                                  _userLongitude!,
                                  food.latitude!,
                                  food.longitude!,
                                )
                              : null,
                          isReceiverMode: true,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Docked CTA Footer
                DockedCTA(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        text: buttonText,
                        isLoading: _isReserving,
                        enabled:
                            isAvailable &&
                            !isOwnFood &&
                            !isExpired &&
                            !_isReserving,
                        onPressed: currentUser != null
                            ? () => _handleReserveFood(
                                currentUser.userId,
                                food.donorId,
                              )
                            : null,
                      ),
                      if (disabledReason != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          disabledReason,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodySmall),
        const Spacer(),
        if (valueWidget != null)
          valueWidget
        else
          Text(value ?? '', style: AppTextStyles.labelLarge),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.restaurant_outlined,
        size: 48.0,
        color: AppColors.textTertiary,
      ),
    );
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}
