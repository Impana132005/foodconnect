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
import '../../../../design_system/components/status_chip.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../food/presentation/providers/food_providers.dart';
import '../../../reservation/presentation/providers/reservation_providers.dart';

class DropAndDoneView extends ConsumerStatefulWidget {
  final String reservationId;
  const DropAndDoneView({super.key, required this.reservationId});

  @override
  ConsumerState<DropAndDoneView> createState() => _DropAndDoneViewState();
}

class _DropAndDoneViewState extends ConsumerState<DropAndDoneView> {
  bool _isCompleting = false;
  String? _errorMessage;

  Future<void> _handleCompleteHandover(String foodId) async {
    if (_isCompleting) return;
    final userProfileAsync = ref.read(userProfileProvider);
    final user = userProfileAsync.value;
    if (user == null) return;

    await showConfirmationDialog(
      context: context,
      title: 'Complete this donation?',
      message: 'This marks the food as picked up and closes the donation.',
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
          reservationId: widget.reservationId,
          foodId: foodId,
          donorId: user.userId,
        );

        if (!mounted) return;

        setState(() {
          _isCompleting = false;
        });

        result.fold(
          (_) {
            ref.invalidate(donorFoodsProvider(user.userId));
            ref.invalidate(foodDetailsProvider(foodId));
            ref.invalidate(reservationStreamProvider(widget.reservationId));
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
              context.go(AppRoutes.donorDashboard);
            }
          },
        ),
        title: Text('Pickup status', style: AppTextStyles.titleLarge),
      ),
      body: SafeArea(
        child: reservationAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: LoadingSkeleton(height: 200),
          ),
          error: (err, _) => ErrorState(
            title: 'Error loading pickup status',
            description: err.toString(),
            onRetry: () =>
                ref.invalidate(reservationStreamProvider(widget.reservationId)),
          ),
          data: (reservation) {
            if (reservation == null) {
              return const EmptyState(
                title: 'Reservation not found',
                description: 'Could not load details for this pickup.',
              );
            }

            final isOtpVerified =
                reservation.status == ReservationStatus.otpVerified ||
                reservation.otpVerified == true;
            final isCompleted =
                reservation.status == ReservationStatus.completed;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Handover verification',
                              style: AppTextStyles.headlineSmall,
                            ),
                            const Spacer(),
                            StatusChip(status: reservation.status.value),
                          ],
                        ),
                        const SizedBox(height: 24),

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
                          const SizedBox(height: 20),
                        ],

                        if (isCompleted) ...[
                          // Result confirmation
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40.0,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Donation completed',
                                    style: AppTextStyles.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'The food handover has been confirmed and completed.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  SecondaryButton(
                                    text: 'Back to dashboard',
                                    onPressed: () =>
                                        context.go(AppRoutes.donorDashboard),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // 3-step vertical stepper
                          _buildStepRow(
                            stepNumber: 1,
                            title: 'Reserved',
                            description: 'Receiver created reservation',
                            isDone: true,
                            isCurrent: false,
                          ),
                          _buildStepLine(),
                          _buildStepRow(
                            stepNumber: 2,
                            title: 'Code verified',
                            description: isOtpVerified
                                ? 'Receiver verified the code'
                                : 'Awaiting code verification',
                            isDone: isOtpVerified,
                            isCurrent: !isOtpVerified,
                          ),
                          _buildStepLine(),
                          _buildStepRow(
                            stepNumber: 3,
                            title: 'Completed',
                            description: 'Food handed over to receiver',
                            isDone: false,
                            isCurrent: isOtpVerified,
                          ),
                          const SizedBox(height: 28),

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
                            child: Text(
                              isOtpVerified
                                  ? 'Receiver verified the code. Confirm the handover to close the donation.'
                                  : 'Share the 6-digit code with the receiver to verify the pickup.',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Docked CTA (only active when step 2 is complete)
                if (isOtpVerified && !isCompleted)
                  DockedCTA(
                    child: AppButton(
                      text: 'Complete donation',
                      isLoading: _isCompleting,
                      onPressed: () =>
                          _handleCompleteHandover(reservation.foodId),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required int stepNumber,
    required String title,
    required String description,
    required bool isDone,
    required bool isCurrent,
  }) {
    Color iconBg = isDone
        ? AppColors.primary
        : (isCurrent ? AppColors.bgReserved : AppColors.surfaceContainerHigh);
    Color iconColor = isDone
        ? AppColors.onPrimary
        : (isCurrent ? AppColors.warning : AppColors.textTertiary);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Center(
            child: isDone
                ? Icon(Icons.check, size: 18, color: iconColor)
                : Text(
                    '$stepNumber',
                    style: AppTextStyles.labelLarge.copyWith(color: iconColor),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDone || isCurrent
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
              Text(description, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, top: 4.0, bottom: 4.0),
      child: Container(
        width: 2.0,
        height: 24.0,
        color: AppColors.outlineVariant,
      ),
    );
  }
}
