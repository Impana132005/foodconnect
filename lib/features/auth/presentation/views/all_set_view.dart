import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/enums.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../models/user_model.dart';
import '../providers/auth_providers.dart';

class AllSetView extends ConsumerWidget {
  final UserModel? user;

  const AllSetView({super.key, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;

    final effectiveUser = user ?? profile;
    final displayName = effectiveUser != null && effectiveUser.name.trim().isNotEmpty
        ? effectiveUser.name.trim()
        : 'New Member';

    final role = effectiveUser?.role ?? UserRole.donor;
    final isDonor = role == UserRole.donor;
    final roleString = isDonor ? 'Donor' : 'Receiver';
    final orgName = effectiveUser?.organizationName.trim() ?? '';
    final roleOrgSubtitle =
        orgName.isNotEmpty ? '$roleString • $orgName' : roleString;

    final emailVerified =
        ref.watch(emailVerifiedProvider) ||
        (ref.watch(authStateProvider).value?.emailVerified ?? false);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40.0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12.0),

                      // Top Brand Mark
                      Center(
                        child: Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 4.0,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.volunteer_activism,
                              color: AppColors.primary,
                              size: 26.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28.0),

                      // Success Check Circle
                      Center(
                        child: Container(
                          width: 72.0,
                          height: 72.0,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1A0E6B3A),
                                blurRadius: 8.0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              color: AppColors.onPrimary,
                              size: 38.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Headings
                      Text(
                        "You're all set!",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 28.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        'Your Food Connect profile is ready. You can now share surplus food or find available food nearby.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28.0),

                      // Profile Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: AppColors.outlineVariant,
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 60.0,
                              height: 60.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceContainerHigh,
                                border: Border.all(
                                  color: AppColors.outlineVariant,
                                  width: 1.0,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: effectiveUser?.profileImageUrl != null &&
                                      effectiveUser!.profileImageUrl!.isNotEmpty
                                  ? Image.network(
                                      effectiveUser.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _buildAvatarFallback(displayName),
                                    )
                                  : _buildAvatarFallback(displayName),
                            ),
                            const SizedBox(width: 16.0),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18.0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    roleOrgSubtitle,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 15.0,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4.0),
                                      Expanded(
                                        child: Text(
                                          'Indiranagar, Bengaluru',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10.0),

                                  // Status Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: AppColors.outlineVariant,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6.0,
                                          height: 6.0,
                                          decoration: const BoxDecoration(
                                            color: AppColors.warning,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6.0),
                                        Text(
                                          'Verification Pending',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                            color: AppColors.textSecondary,
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
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Role-Specific Info Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.onSecondaryContainer,
                              size: 20.0,
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                isDonor
                                    ? "You're ready to share surplus food with your community."
                                    : "You're ready to discover and claim surplus food nearby.",
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.onSecondaryContainer,
                                  fontSize: 13.0,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 24.0),

                      // Bottom Actions
                      AppButton(
                        text: 'Continue to Food Connect',
                        onPressed: () {
                          if (emailVerified) {
                            if (isDonor) {
                              context.go(AppRoutes.donorDashboard);
                            } else {
                              context.go(AppRoutes.receiverDashboard);
                            }
                          } else {
                            context.go(AppRoutes.verifyEmail);
                          }
                        },
                      ),
                      const SizedBox(height: 10.0),
                      GhostButton(
                        text: 'Edit Profile',
                        textColor: AppColors.primary,
                        onPressed: () {
                          context.push(AppRoutes.profile);
                        },
                      ),
                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'FC';

    return Center(
      child: Text(
        initials.toUpperCase(),
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
