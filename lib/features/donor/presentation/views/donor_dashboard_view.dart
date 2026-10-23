import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/enums.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../design_system/components/docked_cta.dart';
import '../../../../design_system/components/empty_state.dart';
import '../../../../design_system/components/loading_skeleton.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../food/presentation/providers/food_providers.dart';
import '../components/donor_food_card.dart';

class DonorDashboardView extends ConsumerStatefulWidget {
  const DonorDashboardView({super.key});

  @override
  ConsumerState<DonorDashboardView> createState() => _DonorDashboardViewState();
}

class _DonorDashboardViewState extends ConsumerState<DonorDashboardView> {
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Donor Dashboard',
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () => context.push(AppRoutes.profile),
            tooltip: 'Profile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: userProfileAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                LoadingSkeleton(height: 80),
                SizedBox(height: 16),
                LoadingSkeleton(height: 160),
              ],
            ),
          ),
          error: (err, stack) => ErrorState(
            title: 'Failed to load profile',
            description: err.toString(),
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
          data: (user) {
            if (user == null) {
              return const EmptyState(
                title: 'No profile found',
                description: 'Please sign in to access your donor dashboard.',
              );
            }

            final donorFoodsAsync = ref.watch(donorFoodsProvider(user.userId));

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(donorFoodsProvider(user.userId));
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Compact Greeting & Verification Row (Stitch Pattern)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${user.name.split(" ").first}',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.organizationName.isNotEmpty
                                        ? user.organizationName
                                        : 'Surplus Food Donor',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              _buildVerificationBadge(
                                user.verificationStatus.value,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 2. Compact Summary Statistics Grid (Stitch 3-Column Pattern)
                          donorFoodsAsync.when(
                            loading: () => const LoadingSkeleton(height: 64),
                            error: (err, _) => const SizedBox.shrink(),
                            data: (foods) {
                              final availableCount = foods
                                  .where(
                                    (f) => f.status == FoodStatus.available,
                                  )
                                  .length;
                              final reservedCount = foods
                                  .where((f) => f.status == FoodStatus.reserved)
                                  .length;
                              final completedCount = foods
                                  .where(
                                    (f) => f.status == FoodStatus.completed,
                                  )
                                  .length;

                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactStatCard(
                                      label: 'Available',
                                      count: '$availableCount',
                                      numberColor: AppColors.primary,
                                      isSelected: _activeFilter == 'Available',
                                      onTap: () => setState(
                                        () => _activeFilter =
                                            _activeFilter == 'Available'
                                                ? 'All'
                                                : 'Available',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactStatCard(
                                      label: 'Reserved',
                                      count: '$reservedCount',
                                      numberColor: AppColors.warning,
                                      isSelected: _activeFilter == 'Reserved',
                                      onTap: () => setState(
                                        () => _activeFilter =
                                            _activeFilter == 'Reserved'
                                                ? 'All'
                                                : 'Reserved',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactStatCard(
                                      label: 'Completed',
                                      count: '$completedCount',
                                      numberColor: AppColors.textPrimary,
                                      isSelected: _activeFilter == 'Completed',
                                      onTap: () => setState(
                                        () => _activeFilter =
                                            _activeFilter == 'Completed'
                                                ? 'All'
                                                : 'Completed',
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // 3. Unified Cohesive Segmented Filter Bar
                          Container(
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
                              children: [
                                'All',
                                'Available',
                                'Reserved',
                                'Completed',
                              ].map((tab) {
                                final isSelected = _activeFilter == tab;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _activeFilter = tab;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(20.0),
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
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
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
                          const SizedBox(height: 16),

                          // 4. Section Header with Breathing Room
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Donations',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              InkWell(
                                onTap: () => ref.invalidate(
                                  donorFoodsProvider(user.userId),
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.refresh,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Refresh',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 5. Donations List with State Precision & Clean Cards
                          donorFoodsAsync.when(
                            loading: () => Column(
                              children: List.generate(
                                2,
                                (index) => const Padding(
                                  padding: EdgeInsets.only(bottom: 12.0),
                                  child: LoadingSkeleton(height: 120),
                                ),
                              ),
                            ),
                            error: (err, _) => ErrorState(
                              title: "Couldn't load donations",
                              description: 'Please check your connection and tap refresh.',
                              onRetry: () => ref.invalidate(
                                donorFoodsProvider(user.userId),
                              ),
                            ),
                            data: (foods) {
                              var filtered = foods;
                              if (_activeFilter != 'All') {
                                filtered = foods.where((f) {
                                  return f.status.value.toLowerCase() ==
                                      _activeFilter.toLowerCase();
                                }).toList();
                              }

                              if (filtered.isEmpty) {
                                return EmptyState(
                                  title: 'No donations yet',
                                  description: _activeFilter == 'All'
                                      ? 'Post surplus food and help someone rescue it before it goes to waste.'
                                      : 'No donations found under "$_activeFilter".',
                                  actionLabel: _activeFilter == 'All'
                                      ? 'Post food'
                                      : null,
                                  onActionPressed: _activeFilter == 'All'
                                      ? () => context.push(AppRoutes.postFood)
                                      : null,
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final food = filtered[index];
                                  return DonorFoodCard(
                                    food: food,
                                    onTap: () {
                                      context.push(
                                        '${AppRoutes.donorFoodDetails}/${food.foodId}',
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

                // 6. Persistent Docked CTA Footer ("+ Post food")
                DockedCTA(
                  child: AppButton(
                    text: 'Post food',
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                    onPressed: () => context.push(AppRoutes.postFood),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(String statusStr) {
    final status = statusStr.toLowerCase();
    final isVerified = status == 'verified';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.primaryContainer
            : AppColors.bgReserved,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.hourglass_empty,
            size: 14,
            color: isVerified
                ? AppColors.primary
                : AppColors.textReserved,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: AppTextStyles.labelSmall.copyWith(
              color: isVerified
                  ? AppColors.onPrimaryContainer
                  : AppColors.textReserved,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required String label,
    required String count,
    required Color numberColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 10.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isSelected ? AppColors.primary : numberColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
