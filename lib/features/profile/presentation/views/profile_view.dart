import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/router.dart';
import '../../../../core/enums.dart';
import '../../../../core/providers.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/components/confirmation_dialog.dart';
import '../../../../design_system/components/empty_state.dart';
import '../../../../design_system/components/loading_skeleton.dart';
import '../../../../models/user_model.dart';
import '../../../../services/location_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool _isUploadingAvatar = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isGettingLocation = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _orgController = TextEditingController();

  double? _tempLatitude;
  double? _tempLongitude;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  void _enterEditMode(UserProfile user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _orgController.text = user.organizationName;
    _tempLatitude = user.latitude;
    _tempLongitude = user.longitude;
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _handleSave(UserProfile currentUser) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = currentUser.copyWith(
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : currentUser.name,
        phone: _phoneController.text.trim(),
        organizationName: _orgController.text.trim(),
        latitude: _tempLatitude,
        longitude: _tempLongitude,
      );

      final userRepo = ref.read(userRepositoryProvider);
      final result = await userRepo.updateUserProfile(updatedProfile);

      if (!mounted) return;

      result.fold(
        (savedProfile) {
          setState(() {
            _isEditing = false;
          });
          ref.invalidate(userProfileProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updateLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      if (!mounted) return;
      if (position != null) {
        setState(() {
          _tempLatitude = position.latitude;
          _tempLongitude = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not get location. Ensure permissions are granted.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _handleUploadAvatar(String uid) async {
    if (_isUploadingAvatar) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final storageRepo = ref.read(storageRepositoryProvider);
      final uploadResult = await storageRepo.uploadUserAvatar(
        uid,
        File(picked.path),
      );

      if (!mounted) return;

      uploadResult.fold(
        (downloadUrl) async {
          final userProfileAsync = ref.read(userProfileProvider);
          final profile = userProfileAsync.value;
          if (profile != null) {
            final updated = profile.copyWith(profileImageUrl: downloadUrl);
            final userRepo = ref.read(userRepositoryProvider);
            await userRepo.updateUserProfile(updated);
            if (mounted) {
              ref.invalidate(userProfileProvider);
            }
          }
        },
        (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.error),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await showConfirmationDialog(
      context: context,
      title: 'Log out of Surplus?',
      message: 'You will need to sign in again to access your account.',
      confirmLabel: 'Log out',
      cancelLabel: 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.logout();
      },
    );
  }

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Profile', style: AppTextStyles.titleLarge),
        actions: [
          userProfileAsync.whenOrNull(
                data: (user) {
                  if (user != null) {
                    return _isEditing
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textPrimary,
                            ),
                            onPressed: _cancelEdit,
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.textPrimary,
                            ),
                            onPressed: () => _enterEditMode(user),
                          );
                  }
                  return null;
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: SafeArea(
        child: userProfileAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: LoadingSkeleton(height: 250),
          ),
          error: (err, _) => ErrorState(
            title: 'Error loading profile',
            description: err.toString(),
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
          data: (user) {
            if (user == null) {
              return const EmptyState(
                title: 'Not signed in',
                description: 'Please sign in to view your profile details.',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Avatar Identity Header
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceContainerHigh,
                          border: Border.all(
                            color: AppColors.outlineVariant,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: user.profileImageUrl != null
                              ? Image.network(
                                  user.profileImageUrl!,
                                  cacheWidth: 192,
                                  cacheHeight: 192,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatarLetter(user),
                                )
                              : _buildDefaultAvatarLetter(user),
                        ),
                      ),
                      if (!_isEditing)
                        InkWell(
                          onTap: _isUploadingAvatar
                              ? null
                              : () => _handleUploadAvatar(user.userId),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.onPrimary,
                                    size: 14,
                                  ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name & Verified Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: AppTextStyles.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: user.verificationStatus.value == 'verified'
                              ? AppColors.primaryContainer
                              : AppColors.bgReserved,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.verificationStatus.value == 'verified'
                                  ? Icons.verified
                                  : Icons.hourglass_empty,
                              size: 14,
                              color: user.verificationStatus.value == 'verified'
                                  ? AppColors.primary
                                  : AppColors.textReserved,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.verificationStatus.value == 'verified'
                                  ? 'Verified'
                                  : 'Pending',
                              style: AppTextStyles.labelSmall.copyWith(
                                color:
                                    user.verificationStatus.value == 'verified'
                                        ? AppColors.onPrimaryContainer
                                        : AppColors.textReserved,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.role == UserRole.donor ? "Donor" : "Receiver"}${user.organizationName.isNotEmpty ? " • ${user.organizationName}" : ""}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Impact Stats Cards (Stitch Pattern)
                  if (!_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: AppColors.outlineVariant,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  user.role == UserRole.donor ? 'Active' : 'Rescue',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.role == UserRole.donor
                                      ? 'Donations Posted'
                                      : 'Food Rescues',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 12.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: AppColors.outlineVariant,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '100%',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pickup Reliability',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Contact Information Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: AppColors.outlineVariant,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_isEditing) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                AppTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _phoneController,
                                  label: 'Phone',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _orgController,
                                  label: 'Organization',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _tempLatitude != null &&
                                                _tempLongitude != null
                                            ? 'Lat: ${_tempLatitude!.toStringAsFixed(4)}, Lng: ${_tempLongitude!.toStringAsFixed(4)}'
                                            : 'No location set',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ),
                                    SecondaryButton(
                                      text: 'Get GPS',
                                      isFullWidth: false,
                                      isLoading: _isGettingLocation,
                                      onPressed: _updateLocation,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          _buildStitchContactRow(
                            Icons.mail_outline,
                            'Email Address',
                            user.email,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 64,
                            color: AppColors.outlineVariant,
                          ),
                          _buildStitchContactRow(
                            Icons.phone_outlined,
                            'Mobile Number',
                            user.phone.isNotEmpty ? user.phone : 'Not provided',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service Location Card (Stitch Pattern)
                  if (!_isEditing) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: AppColors.outlineVariant,
                          width: 1.0,
                        ),
                      ),
                      child: _buildStitchContactRow(
                        Icons.location_on_outlined,
                        'Primary Service Area',
                        user.latitude != null && user.longitude != null
                            ? 'Lat: ${user.latitude!.toStringAsFixed(4)}, Lng: ${user.longitude!.toStringAsFixed(4)}'
                            : 'Bengaluru, India',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Account & Preferences Card (Stitch Pattern)
                  if (!_isEditing) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: AppColors.outlineVariant,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildStitchNavRow(
                            Icons.lock_outline,
                            'Change Password',
                            onTap: () {
                              context.push(AppRoutes.changePassword);
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 64,
                            color: AppColors.outlineVariant,
                          ),
                          _buildStitchNavRow(
                            Icons.notifications_none_outlined,
                            'Notification Preferences',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notifications are active.'),
                                ),
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 64,
                            color: AppColors.outlineVariant,
                          ),
                          _buildStitchNavRow(
                            Icons.shield_outlined,
                            'Privacy & Security',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All data is encrypted.'),
                                ),
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 64,
                            color: AppColors.outlineVariant,
                          ),
                          // Log Out Row inside Card (Stitch Exact Pattern)
                          InkWell(
                            onTap: _handleLogout,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.errorContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    'Log Out',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.error,
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
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 8),
                    AppButton(
                      text: 'Save Changes',
                      isLoading: _isSaving,
                      onPressed: () => _handleSave(user),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultAvatarLetter(UserProfile user) {
    return Center(
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
        style: AppTextStyles.titleLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStitchContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchNavRow(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
