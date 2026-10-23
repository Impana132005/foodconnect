import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/enums.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../design_system/components/confirmation_dialog.dart';
import '../../../../design_system/components/empty_state.dart';
import '../../../../design_system/components/expiry_countdown.dart';
import '../../../../design_system/components/loading_skeleton.dart';
import '../../../../design_system/components/otp_field.dart';
import '../../../../design_system/components/section_header.dart';
import '../../../food/presentation/components/pickup_location_card.dart';
import '../../../food/presentation/providers/food_providers.dart';
import '../providers/reservation_providers.dart';

class ReservationView extends ConsumerStatefulWidget {
  final String reservationId;
  const ReservationView({super.key, required this.reservationId});

  @override
  ConsumerState<ReservationView> createState() => _ReservationViewState();
}

class _ReservationViewState extends ConsumerState<ReservationView>
    with WidgetsBindingObserver {
  String _enteredOtp = '';
  bool _isVerifying = false;
  bool _isCancelling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force re-evaluation of deadline expiry on app resume
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleVerifyOtp(String receiverId) async {
    if (_isVerifying || _enteredOtp.length < 6) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final repo = ref.read(reservationRepositoryProvider);
    final result = await repo.verifyOtp(
      reservationId: widget.reservationId,
      enteredOtp: _enteredOtp,
      receiverId: receiverId,
    );

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    result.fold(
      (_) {
        ref.invalidate(reservationStreamProvider(widget.reservationId));
      },
      (error) {
        setState(() {
          _errorMessage = error;
        });
      },
    );
  }

  Future<void> _handleCancel(String foodId, String receiverId) async {
    if (_isCancelling) return;
    await showConfirmationDialog(
      context: context,
      title: 'Cancel this reservation?',
      message:
          "If the food hasn't expired, it will return to the available list for other receivers.",
      confirmLabel: 'Cancel reservation',
      cancelLabel: 'Keep reservation',
      isDestructive: true,
      onConfirm: () async {
        if (_isCancelling) return;
        setState(() {
          _isCancelling = true;
        });

        final repo = ref.read(reservationRepositoryProvider);
        final result = await repo.cancelReservation(
          reservationId: widget.reservationId,
          foodId: foodId,
          receiverId: receiverId,
        );

        if (!mounted) return;

        setState(() {
          _isCancelling = false;
        });

        result.fold(
          (_) {
            ref.invalidate(availableFoodsStreamProvider);
            ref.invalidate(reservationStreamProvider(widget.reservationId));
            context.go(AppRoutes.receiverDashboard);
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
    final reservationAsync = ref.watch(
      reservationStreamProvider(widget.reservationId),
    );

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
        title: Text('Active pickup', style: AppTextStyles.titleLarge),
      ),
      body: SafeArea(
        child: reservationAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: LoadingSkeleton(height: 250),
          ),
          error: (err, _) => ErrorState(
            title: 'Failed to load reservation',
            description: err.toString(),
            onRetry: () =>
                ref.invalidate(reservationStreamProvider(widget.reservationId)),
          ),
          data: (reservation) {
            if (reservation == null) {
              return const EmptyState(
                title: 'Reservation not found',
                description:
                    'This reservation does not exist or has been removed.',
              );
            }

            final foodAsync = ref.watch(
              foodDetailsProvider(reservation.foodId),
            );
            final food = foodAsync.value;

            final isOtpVerified =
                reservation.status == ReservationStatus.otpVerified ||
                reservation.otpVerified == true;
            final isCompleted =
                reservation.status == ReservationStatus.completed;
            final isExpired =
                reservation.status == ReservationStatus.expired ||
                (reservation.status == ReservationStatus.active &&
                    DateTime.now().isAfter(reservation.pickupDeadline));

            if (isExpired) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.timer_off_outlined,
                          size: 32,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text("Time's up", style: AppTextStyles.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'The 30-minute pickup window for this food has closed.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        text: 'Back to available food',
                        onPressed: () =>
                            context.go(AppRoutes.receiverDashboard),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Timer Section (Stitch Exact Pattern)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.0,
                                height: 8.0,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'Reservation Confirmed',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Time remaining to pickup',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        ExpiryCountdown(
                          targetTime: reservation.pickupDeadline,
                          size: ExpiryCountdownSize.large,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Food Details Card (Stitch Pattern)
                  if (food != null) ...[
                    Container(
                      width: double.infinity,
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
                          if (food.imageUrl != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12.0),
                              ),
                              child: Image.network(
                                food.imageUrl!,
                                cacheWidth: 800,
                                cacheHeight: 400,
                                height: 130.0,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food.foodName,
                                        style: AppTextStyles.titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Food Donation',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.restaurant_outlined,
                                        size: 14.0,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        food.quantity,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                            size: 20,
                          ),
                          const SizedBox(width: 8),
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
                    const SizedBox(height: 16),
                  ],

                  // Pickup Location Card
                  PickupLocationCard(
                    latitude: food?.latitude,
                    longitude: food?.longitude,
                    placeName: food != null ? '${food.foodName} Pickup' : 'Donor Facility',
                    isReceiverMode: true,
                  ),
                  const SizedBox(height: 20),

                  // Section: Verify pickup
                  const SectionHeader(title: 'Verify pickup'),
                  if (isOtpVerified || isCompleted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Code verified — collect your food',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ask the donor to tap Drop & Done on their phone to close the donation.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Ask the donor to share their 6-digit code.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OTPField(
                      isError: _errorMessage != null,
                      onChanged: (code) {
                        setState(() {
                          _enteredOtp = code;
                        });
                      },
                      onCompleted: (code) {
                        _enteredOtp = code;
                        _handleVerifyOtp(reservation.receiverId);
                      },
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Verify code',
                      isLoading: _isVerifying,
                      enabled: _enteredOtp.length == 6 && !_isVerifying,
                      onPressed: () => _handleVerifyOtp(reservation.receiverId),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Cancel action
                  if (!isOtpVerified && !isCompleted) ...[
                    Center(
                      child: GhostButton(
                        text: 'Cancel reservation',
                        textColor: AppColors.error,
                        onPressed: _isCancelling
                            ? null
                            : () => _handleCancel(
                                reservation.foodId,
                                reservation.receiverId,
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
