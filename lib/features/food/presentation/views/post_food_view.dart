import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/enums.dart';
import '../../../../core/validation.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/components/docked_cta.dart';
import '../../../../design_system/components/option_card.dart';
import '../../../../design_system/components/section_header.dart';
import '../../../../models/food_model.dart';
import '../../../../core/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../components/pickup_location_card.dart';
import '../providers/food_providers.dart';

final DateFormat _expiryTimeFormat = DateFormat('h:mm a');

class PostFoodView extends ConsumerStatefulWidget {
  const PostFoodView({super.key});

  @override
  ConsumerState<PostFoodView> createState() => _PostFoodViewState();
}

class _PostFoodViewState extends ConsumerState<PostFoodView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  FoodType _selectedType = FoodType.cooked;
  final DateTime _preparedAt = DateTime.now();
  File? _imageFile;
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;
  String? _locationError;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    if (!mounted) return;
    setState(() {
      _isFetchingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = false;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        // Suppress platform errors from missing Play Services location broker
      }

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isFetchingLocation = false;
            _locationError = 'Location services are disabled on this device.';
          });
        }
        return;
      }

      LocationPermission permission = LocationPermission.denied;
      try {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      } catch (e) {
        // Suppress permission check errors
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isFetchingLocation = false;
            _locationError = 'Location permission was denied. Please allow access in settings.';
          });
        }
        return;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        try {
          pos = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          if (pos != null) {
            _latitude = pos.latitude;
            _longitude = pos.longitude;
            _locationError = null;
          } else {
            _locationError = "Couldn't retrieve GPS location. Please try again.";
          }
          _isFetchingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
          _locationError = "Couldn't get location. Please try again.";
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting photo: $e')));
      }
    }
  }

  Future<void> _handlePostFood() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      setState(() {
        _errorMessage = 'Please add a photo before posting.';
      });
      return;
    }

    final userProfileAsync = ref.read(userProfileProvider);
    final user = userProfileAsync.value;
    if (user == null) {
      setState(() {
        _errorMessage = 'User session not found. Please log in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? imageUrl;
      if (_imageFile != null) {
        final storageRepo = ref.read(storageRepositoryProvider);
        final uploadResult = await storageRepo.uploadFoodImage(
          DateTime.now().millisecondsSinceEpoch.toString(),
          _imageFile!,
        );

        if (!mounted) return;

        final uploadSuccess = uploadResult.fold(
          (url) {
            imageUrl = url;
            return true;
          },
          (err) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Photo upload failed: $err';
              });
            }
            return false;
          },
        );

        if (!uploadSuccess) return;
      }

      final calculatedExpiry = Food.calculateExpiryAt(
        _selectedType,
        _preparedAt,
      );

      final foodItem = Food(
        foodId: '',
        donorId: user.userId,
        foodName: _nameController.text.trim(),
        quantity: _quantityController.text.trim(),
        foodType: _selectedType,
        preparedAt: _preparedAt,
        expiryAt: calculatedExpiry,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        status: FoodStatus.available,
        latitude: _latitude,
        longitude: _longitude,
      );

      final foodRepo = ref.read(foodRepositoryProvider);
      final createResult = await foodRepo.createFood(foodItem);

      if (!mounted) return;

      createResult.fold(
        (food) {
          ref.invalidate(donorFoodsProvider(user.userId));
          ref.invalidate(availableFoodsStreamProvider);
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.donorDashboard);
          }
        },
        (error) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculatedExpiry = Food.calculateExpiryAt(_selectedType, _preparedAt);
    final formattedExpiry = _expiryTimeFormat.format(calculatedExpiry);
    final expiryHours = _selectedType == FoodType.cooked ? '4h 00m' : '8h 00m';

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
        title: Text('Post food', style: AppTextStyles.titleLarge),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expiry is set automatically from the food type.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16.0),

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

                      // 16:9 Hero Photo Slot with Dashed Border
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: AppColors.outline,
                              width: 1.5,
                              style: _imageFile == null
                                  ? BorderStyle.solid
                                  : BorderStyle.none,
                            ),
                          ),
                          child: _imageFile != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20.0),
                                      child: Image.file(
                                        _imageFile!,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer
                                              .withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Change',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.camera_alt_outlined,
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add a photo',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Photo is required for food safety verification',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section: What are you donating?
                      const SectionHeader(title: 'What are you donating?'),
                      AppTextField(
                        label: 'Food name',
                        hintText: 'e.g. Vegetable Curry & Rice',
                        controller: _nameController,
                        validator: AppValidators.validateFoodName,
                      ),
                      const SizedBox(height: 16),

                      OptionCard(
                        title: 'Cooked',
                        description: 'Expires 4 h after prep',
                        icon: Icons.soup_kitchen_outlined,
                        isSelected: _selectedType == FoodType.cooked,
                        onTap: () {
                          setState(() {
                            _selectedType = FoodType.cooked;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      OptionCard(
                        title: 'Packed',
                        description: 'Expires 8 h after prep',
                        icon: Icons.inventory_2_outlined,
                        isSelected: _selectedType == FoodType.packed,
                        onTap: () {
                          setState(() {
                            _selectedType = FoodType.packed;
                          });
                        },
                      ),

                      // Section: Details
                      const SectionHeader(title: 'Details'),
                      AppTextField(
                        label: 'Quantity / servings',
                        hintText: 'e.g. 12 servings or 3 kg',
                        controller: _quantityController,
                        validator: AppValidators.validateQuantity,
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Description',
                        hintText:
                            'Allergen info or special pickup instructions',
                        controller: _descriptionController,
                        maxLines: 3,
                        validator: (val) =>
                            AppValidators.validateRequired(val, 'Description'),
                      ),

                      // Section: Timing
                      const SectionHeader(title: 'Timing'),
                      // Live Expiry Preview Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expires in $expiryHours (at $formattedExpiry)',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.onPrimaryContainer,
                                    ),
                                  ),
                                  Text(
                                    'Calculated automatically from prep time',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Section: Location
                      const SectionHeader(title: 'Pickup location'),
                      PickupLocationCard(
                        latitude: _latitude,
                        longitude: _longitude,
                        placeName: ref.watch(userProfileProvider).valueOrNull?.organizationName.isNotEmpty == true
                            ? ref.watch(userProfileProvider).valueOrNull!.organizationName
                            : (ref.watch(userProfileProvider).valueOrNull?.name.isNotEmpty == true
                                ? ref.watch(userProfileProvider).valueOrNull!.name
                                : 'Community Kitchen / Facility'),
                        isLoading: _isFetchingLocation,
                        errorMessage: _locationError,
                        onFetchLocation: _fetchLocation,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Docked CTA Footer
            DockedCTA(
              child: AppButton(
                text: 'Post food',
                isLoading: _isLoading,
                onPressed: _handlePostFood,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
