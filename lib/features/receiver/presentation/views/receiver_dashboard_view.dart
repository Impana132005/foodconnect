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
import '../../../../design_system/components/food_card.dart';
import '../../../../design_system/components/loading_skeleton.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../food/presentation/providers/food_providers.dart';
import '../../../../services/location_service.dart';

class ReceiverDashboardView extends ConsumerStatefulWidget {
  const ReceiverDashboardView({super.key});

  @override
  ConsumerState<ReceiverDashboardView> createState() =>
      _ReceiverDashboardViewState();
}

class _ReceiverDashboardViewState extends ConsumerState<ReceiverDashboardView> {
  String _selectedFilter = 'all'; // 'all', 'cooked', 'packed'
  bool _nearestFirst = true;
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

  @override
  Widget build(BuildContext context) {
    final availableFoodsAsync = ref.watch(availableFoodsStreamProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Food Connect',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stitch Greeting Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        userProfileAsync.maybeWhen(
                          data: (user) => Text(
                            user != null
                                ? 'Good day, ${user.name.split(" ").first}.'
                                : 'Welcome to Food Connect',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          orElse: () => Text(
                            'Available Food',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Available surplus food near you.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Bar & Sort Toggle (Stitch Pill Style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All', 'all'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Cooked', 'cooked'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Packed', 'packed'),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _nearestFirst = !_nearestFirst;
                            });
                          },
                          borderRadius: BorderRadius.circular(20.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              color: _nearestFirst
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: _nearestFirst
                                    ? AppColors.primary
                                    : AppColors.outlineVariant,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me_outlined,
                                  size: 14,
                                  color: _nearestFirst
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nearest',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: _nearestFirst
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Food Feed List
                  Expanded(
                    child: availableFoodsAsync.when(
                      loading: () => ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: 4,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            const LoadingSkeleton(height: 90),
                      ),
                      error: (err, stackTrace) => ErrorState(
                        title: 'Error loading food feed',
                        description: err.toString(),
                        onRetry: () =>
                            ref.invalidate(availableFoodsStreamProvider),
                      ),
                      data: (foods) {
                        final locationService = LocationService();
                        final hasUserLocation =
                            _userLatitude != null && _userLongitude != null;

                        // Precalculate distance map in O(N)
                        final distanceMap = <String, double>{};
                        if (hasUserLocation) {
                          for (final f in foods) {
                            if (f.latitude != null && f.longitude != null) {
                              distanceMap[f.foodId] =
                                  locationService.calculateDistance(
                                    _userLatitude!,
                                    _userLongitude!,
                                    f.latitude!,
                                    f.longitude!,
                                  );
                            }
                          }
                        }

                        var filtered = foods.where((f) {
                          if (_selectedFilter == 'cooked') {
                            return f.foodType == FoodType.cooked;
                          }
                          if (_selectedFilter == 'packed') {
                            return f.foodType == FoodType.packed;
                          }
                          return true;
                        }).toList();

                        if (_nearestFirst && hasUserLocation) {
                          filtered.sort((a, b) {
                            final distA = distanceMap[a.foodId] ?? double.infinity;
                            final distB = distanceMap[b.foodId] ?? double.infinity;
                            return distA.compareTo(distB);
                          });
                        }

                        if (filtered.isEmpty) {
                          return EmptyState(
                            title: 'No food available right now',
                            description:
                                'When a donor posts nearby surplus food, it will appear here.',
                            actionLabel: 'Refresh feed',
                            onActionPressed: () =>
                                ref.invalidate(availableFoodsStreamProvider),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(availableFoodsStreamProvider);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final food = filtered[index];
                              final dist = distanceMap[food.foodId];
                              return FoodCard(
                                title: food.foodName,
                                quantity: food.quantity,
                                foodType: food.foodType.value,
                                preparedAt: food.preparedAt,
                                expiryAt: food.expiryAt,
                                imageUrl: food.imageUrl,
                                status: food.status.value,
                                distance: dist != null
                                    ? '${dist.toStringAsFixed(1)} km'
                                    : null,
                                onTap: () {
                                  context.push(
                                    '${AppRoutes.foodDetails}/${food.foodId}',
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Docked CTA Footer ("My reservations")
            DockedCTA(
              child: SecondaryButton(
                text: 'My reservations',
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                onPressed: () => context.push(AppRoutes.myReservations),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      borderRadius: BorderRadius.circular(24.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant,
            width: 1.0,
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
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected
                ? AppColors.onPrimaryContainer
                : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
