import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router.dart';
import '../../../../core/enums.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../design_system/components/empty_state.dart';
import '../../../../design_system/components/expiry_countdown.dart';
import '../../../../design_system/components/loading_skeleton.dart';
import '../../../../design_system/components/status_chip.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/reservation_providers.dart';

final DateFormat _reservationDateFormat = DateFormat('MMM dd · h:mm a');

class MyReservationsView extends ConsumerStatefulWidget {
  const MyReservationsView({super.key});

  @override
  ConsumerState<MyReservationsView> createState() => _MyReservationsViewState();
}

class _MyReservationsViewState extends ConsumerState<MyReservationsView> {
  String _activeTab = 'Active'; // Active, Completed, Cancelled

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

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
        title: Text('My reservations', style: AppTextStyles.titleLarge),
      ),
      body: SafeArea(
        child: userProfileAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => const LoadingSkeleton(height: 110),
          ),
          error: (err, stackTrace) => ErrorState(
            title: 'Error loading profile',
            description: err.toString(),
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
          data: (user) {
            if (user == null) {
              return const EmptyState(
                title: 'Not signed in',
                description: 'Please sign in to view your reservations.',
              );
            }

            final reservationsAsync = ref.watch(
              receiverReservationsProvider(user.userId),
            );

            return Column(
              children: [
                // Segmented Control Tabs (Active · Completed · Cancelled)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: AppColors.outlineVariant,
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: ['Active', 'Completed', 'Cancelled'].map((tab) {
                        final isSelected = _activeTab == tab;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeTab = tab;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20.0),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2),
                                          blurRadius: 4.0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                tab,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.onPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Reservations List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(receiverReservationsProvider(user.userId));
                    },
                    child: reservationsAsync.when(
                      loading: () => ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: 3,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            const LoadingSkeleton(height: 110),
                      ),
                      error: (err, stackTrace) => ErrorState(
                        title: 'Error loading reservations',
                        description: err.toString(),
                        onRetry: () => ref.invalidate(
                          receiverReservationsProvider(user.userId),
                        ),
                      ),
                      data: (reservations) {
                        var filtered = reservations.where((r) {
                          if (_activeTab == 'Active') {
                            return r.status == ReservationStatus.active ||
                                r.status == ReservationStatus.otpVerified;
                          } else if (_activeTab == 'Completed') {
                            return r.status == ReservationStatus.completed;
                          } else {
                            return r.status == ReservationStatus.cancelled ||
                                r.status == ReservationStatus.expired;
                          }
                        }).toList();

                        if (filtered.isEmpty) {
                          return EmptyState(
                            title: _activeTab == 'Active'
                                ? 'No active pickups'
                                : (_activeTab == 'Completed'
                                      ? 'No completed pickups'
                                      : 'No cancelled pickups'),
                            description: _activeTab == 'Active'
                                ? 'Browse available food and make a reservation to start a pickup.'
                                : 'Your past reservations will appear here.',
                            actionLabel: _activeTab == 'Active'
                                ? 'Browse food'
                                : null,
                            onActionPressed: _activeTab == 'Active'
                                ? () => context.go(AppRoutes.receiverDashboard)
                                : null,
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final res = filtered[index];
                            final dateStr = _reservationDateFormat.format(
                              res.reservedAt,
                            );
                            final isActive = _activeTab == 'Active';

                            return Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: AppColors.outlineVariant,
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8.0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      StatusChip(status: res.status.value),
                                      const Spacer(),
                                      if (isActive)
                                        ExpiryCountdown(
                                          targetTime: res.pickupDeadline,
                                        )
                                      else
                                        Text(
                                          dateStr,
                                          style: AppTextStyles.caption,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Reservation #${res.reservationId.substring(0, res.reservationId.length > 8 ? 8 : res.reservationId.length)}',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Verification code: ${res.otp}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(height: 14),
                                    SecondaryButton(
                                      text: 'Continue pickup',
                                      icon: const Icon(
                                        Icons.arrow_forward,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        context.push(
                                          '${AppRoutes.reservation}/${res.reservationId}',
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
